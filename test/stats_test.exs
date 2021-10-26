defmodule TestStatsHandler do
  require Logger
  use Riverside, otp_app: :riverside

  @impl Riverside
  def authenticate(_req) do
    {:ok, 1, %{}}
  end

  @impl Riverside
  def handle_message(msg, session, state) do
    if msg["dont_deliver"] do
      {:ok, session, state}
    else
      deliver_me(msg)
      {:ok, session, state}
    end
  end
end

defmodule Riverside.StatsTest do
  use ExUnit.Case

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do
    Riverside.IO.Timestamp.Sandbox.start_link()
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link()
    Riverside.IO.Random.Sandbox.mode(:real)

    Riverside.Stats.start_link()

    {:ok, pid} = TestServer.start(TestStatsHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  test "stats" do
    # check first state, all number should be zero
    stats1 = Riverside.Stats.current_state()
    assert stats1.total_connections == 0
    assert stats1.current_connections == 0
    assert stats1.incoming_messages == 0
    assert stats1.outgoing_messages == 0

    {:ok, client} = TestClient.start_link(host: "localhost", port: 3000, path: "/")

    # check if connection number incremented
    stats2 = Riverside.Stats.current_state()
    assert stats2.total_connections == 1
    assert stats2.current_connections == 1
    assert stats2.incoming_messages == 0

    TestClient.test_message(%{
      sender: client,
      message: %{"content" => "Hello"},
      receivers: [
        %{
          receiver: client,
          tests: [
            fn msg ->
              assert Map.has_key?(msg, "content")
              assert msg["content"] == "Hello"
            end
          ]
        }
      ]
    })

    :timer.sleep(50)

    # check if both incoming and outgoing message counts incremented
    stats2 = Riverside.Stats.current_state()
    assert stats2.total_connections == 1
    assert stats2.current_connections == 1
    assert stats2.incoming_messages == 1
    assert stats2.outgoing_messages == 1

    TestClient.test_message(%{
      sender: client,
      message: %{"content" => "Hello", "dont_deliver" => true},
      receivers: [
        %{
          receiver: client,
          tests: [
            fn msg ->
              assert Map.has_key?(msg, "content")
              assert msg["content"] == "Hello"
            end
          ]
        }
      ]
    })

    :timer.sleep(50)

    # check if only incoming  message counts incremented
    stats3 = Riverside.Stats.current_state()
    assert stats3.total_connections == 1
    assert stats3.current_connections == 1
    assert stats3.incoming_messages == 2
    assert stats3.outgoing_messages == 1

    TestClient.stop(client)

    :timer.sleep(50)

    # check if total connection remains, but current connection is decremented
    stats4 = Riverside.Stats.current_state()
    assert stats4.total_connections == 1
    assert stats4.current_connections == 0
    assert stats4.incoming_messages == 2
    assert stats4.outgoing_messages == 1
  end
end
