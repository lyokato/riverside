defmodule TestChannelBroadcastHandler do
  require Logger
  use Riverside, otp_app: :riverside

  @impl Riverside
  def authenticate(req) do
    channel = req.queries["channel"]

    case req.bearer_token do
      "foo" ->
        {:ok, 1, %{channel: channel}}

      "bar" ->
        {:ok, 2, %{channel: channel}}

      "buz" ->
        {:ok, 3, %{channel: channel}}

      _ ->
        error =
          auth_error_with_code(401)
          |> put_auth_error_bearer_header("example.org", "invalid_token")

        {:error, error}
    end
  end

  @impl Riverside
  def init(session, %{channel: channel} = state) do
    join_channel(channel)

    {:ok, session, state}
  end

  @impl Riverside
  def handle_message(incoming, session, %{channel: channel} = state) do
    content = incoming["content"]

    outgoing = %{"from" => "#{channel}/#{session.user_id}/#{session.id}", "content" => content}

    deliver_channel(channel, outgoing)

    {:ok, session, state}
  end
end

defmodule Riverside.ChannelBroadcastTest do
  use ExUnit.Case

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do
    Riverside.IO.Timestamp.Sandbox.start_link()
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link()
    Riverside.IO.Random.Sandbox.mode(:real)

    Riverside.Stats.start_link()

    {:ok, pid} = TestServer.start(TestChannelBroadcastHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  test "broadcast in channel" do
    {:ok, foo1} =
      TestClient.start_link(
        host: "localhost",
        port: 3000,
        path: "/?channel=1",
        headers: [{:authorization, "Bearer foo"}]
      )

    {:ok, bar} =
      TestClient.start_link(
        host: "localhost",
        port: 3000,
        path: "/?channel=1",
        headers: [{:authorization, "Bearer bar"}]
      )

    {:ok, buz} =
      TestClient.start_link(
        host: "localhost",
        port: 3000,
        path: "/?channel=2",
        headers: [{:authorization, "Bearer buz"}]
      )

    {:ok, foo2} =
      TestClient.start_link(
        host: "localhost",
        port: 3000,
        path: "/?channel=2",
        headers: [{:authorization, "Bearer foo"}]
      )

    TestClient.test_message(%{
      sender: foo1,
      message: %{"to" => "foo", "content" => "Hello"},
      receivers: [
        %{
          receiver: bar,
          tests: [
            fn msg ->
              assert Map.has_key?(msg, "content")
              [channel, user_id, _session_id] = String.split(msg["from"], "/")
              assert channel == "1"
              assert user_id == "foo"
              assert msg["content"] == "Hello"
            end
          ]
        },
        %{
          receiver: foo1,
          tests: [
            fn msg ->
              assert Map.has_key?(msg, "content")
              [channel, user_id, _session_id] = String.split(msg["from"], "/")
              assert channel == "1"
              assert user_id == "foo"
              assert msg["content"] == "Hello"
            end
          ]
        }
      ]
    })

    TestClient.test_message(%{
      sender: buz,
      message: %{"to" => "foo", "content" => "Hey"},
      receivers: [
        %{
          receiver: foo2,
          tests: [
            fn msg ->
              assert Map.has_key?(msg, "content")
              [channel, user_id, _session_id] = String.split(msg["from"], "/")
              assert channel == "2"
              assert user_id == "bar"
              assert msg["content"] == "Hey"
            end
          ]
        },
        %{
          receiver: buz,
          tests: [
            fn msg ->
              assert Map.has_key?(msg, "content")
              [channel, user_id, _session_id] = String.split(msg["from"], "/")
              assert channel == "2"
              assert user_id == "bar"
              assert msg["content"] == "Hey"
            end
          ]
        }
      ]
    })
  end
end
