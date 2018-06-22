defmodule TestDirectRelayHandler do

  require Logger
  use Riverside, otp_app: :riverside

  @impl Riverside
  def authenticate(req) do
    case req.bearer_token do
      "foo" -> {:ok, 1, %{}}
      "bar" -> {:ok, 1, %{}}
      _     ->
        error = auth_error_with_code(401)
              |> put_auth_error_bearer_header("example.org", "invalid_token")
        {:error, error}
    end
  end

  @impl Riverside
  def handle_message(incoming, session, state) do

    dest_user = incoming["to"]
    content   = incoming["content"]

    outgoing = %{"from"    => "#{session.user_id}/#{session.id}",
                 "content" => content}

    deliver_user(dest_user, outgoing)

    {:ok, session, state}
  end

end

defmodule Riverside.DirectRelayTest do

  use ExUnit.Case

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do

    Riverside.IO.Timestamp.Sandbox.start_link
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link
    Riverside.IO.Random.Sandbox.mode(:real)

    Riverside.MetricsInstrumenter.setup()

    {:ok, pid} = TestServer.start(TestDirectRelayHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  test "direct relay message" do
    {:ok, foo} = TestClient.start_link(host: "localhost", port: 3000, path: "/",
                                       headers: [{:authorization, "Bearer foo"}])

    {:ok, bar} = TestClient.start_link(host: "localhost", port: 3000, path: "/",
                                       headers: [{:authorization, "Bearer bar"}])

    TestClient.test_message(%{
      sender: foo,
      message: %{"to" => "foo",  "content" => "Hello"},
      receivers: [%{receiver: bar, tests: [
        fn msg ->
          assert Map.has_key?(msg, "content")
          [user_id, _session_id] = String.split(msg["from"], "/")
          assert user_id == "foo"
          assert msg["content"] == "Hello"
        end
      ]}]
    })

    TestClient.test_message(%{
      sender: bar,
      message: %{"to" => "foo",  "content" => "Hey"},
      receivers: [%{receiver: foo, tests: [
        fn msg ->
          assert Map.has_key?(msg, "content")
          [user_id, _session_id] = String.split(msg["from"], "/")
          assert user_id == "bar"
          assert msg["content"] == "Hey"
        end
      ]}]
    })

  end

end
