defmodule TestMetricsHandler do

  require Logger
  use Riverside, otp_app: :riverside

  @impl Riverside.Behaviour
  def authenticate(_req) do
    {:ok, 1, %{}}
  end

  @impl Riverside.Behaviour
  def handle_message(msg, session, state) do
    if msg["dont_deliver"] do
      {:ok, session, state}
    else
      deliver_me(msg)
      {:ok, session, state}
    end
  end

end

defmodule Riverside.MetricsTest do

  use ExUnit.Case

  use Plug.Test

  alias Riverside.Router
  @opts Router.init([])

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do


    Riverside.IO.Timestamp.Sandbox.start_link
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link
    Riverside.IO.Random.Sandbox.mode(:real)

    Riverside.MetricsInstrumenter.setup()
    Riverside.MetricsExporter.setup()

    {:ok, pid} = TestServer.start(TestMetricsHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  test "metrics" do

    # check first state, all number should be zero
    stats1 = get_metrics()
    assert stats1["riverside_sessions_total"]== 0
    assert stats1["riverside_connected_sessions_count"]== 0
    assert stats1["riverside_incoming_messages_total"]== nil
    assert stats1["riverside_outgoing_messages_total"]== nil

    {:ok, client} = TestClient.start_link(host: "localhost", port: 3000, path: "/")

    # check if connection number incremented
    stats2 = get_metrics()
    assert stats2["riverside_sessions_total"]== 1
    assert stats2["riverside_connected_sessions_count"]== 1
    assert stats2["riverside_incoming_messages_total"]== nil
    assert stats2["riverside_outgoing_messages_total"]== nil

    TestClient.test_message(%{
      sender: client,
      message: %{"content" => "Hello"},
      receivers: [%{receiver: client, tests: [
        fn msg ->
          assert Map.has_key?(msg, "content")
          assert msg["content"] == "Hello"
        end
      ]}]
    })

    :timer.sleep(50)

    # check if both incoming and outgoing message counts incremented
    stats3 = get_metrics()
    assert stats3["riverside_sessions_total"]== 1
    assert stats3["riverside_connected_sessions_count"]== 1
    assert stats3["riverside_incoming_messages_total{frame_type=\"text\"}"]== 1
    assert stats3["riverside_outgoing_messages_total{frame_type=\"text\"}"]== 1

    TestClient.test_message(%{
      sender: client,
      message: %{"content" => "Hello", "dont_deliver" => true },
      receivers: [%{receiver: client, tests: [
        fn msg ->
          assert Map.has_key?(msg, "content")
          assert msg["content"] == "Hello"
        end
      ]}]
    })

    :timer.sleep(50)

    # check if only incoming  message counts incremented
    stats4 = get_metrics()
    assert stats4["riverside_sessions_total"]== 1
    assert stats4["riverside_connected_sessions_count"]== 1
    assert stats4["riverside_incoming_messages_total{frame_type=\"text\"}"]== 2
    assert stats4["riverside_outgoing_messages_total{frame_type=\"text\"}"]== 1

    TestClient.stop(client)

    :timer.sleep(50)

    # check if total connection remains, but current connection is decremented
    stats5 = get_metrics()
    assert stats5["riverside_sessions_total"]== 1
    assert stats5["riverside_connected_sessions_count"]== 0
    assert stats5["riverside_incoming_messages_total{frame_type=\"text\"}"]== 2
    assert stats5["riverside_outgoing_messages_total{frame_type=\"text\"}"]== 1

  end

  defp get_metrics() do
    conn = conn(:get, "/metrics")
    conn = Router.call(conn, @opts)
    assert conn.state == :sent
    assert conn.status == 200
    String.split(conn.resp_body, "\n")
    |> Enum.filter(&Regex.match?(~r/^riverside_/, &1))
    |> Enum.map(&String.split(&1, " "))
    |> Map.new(fn parts ->
      key = Enum.at(parts, 0)
      {val, _} = Enum.at(parts, 1) |> Integer.parse()
      {key, val}
    end)
  end

end
