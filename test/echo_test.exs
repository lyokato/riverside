defmodule TestEchoHandler do
  require Logger
  use Riverside, otp_app: :riverside

  @impl Riverside
  def authenticate(_req) do
    {:ok, 1, %{}}
  end

  @impl Riverside
  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end
end

defmodule Riverside.EchoTest do
  use ExUnit.Case

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do
    Riverside.IO.Timestamp.Sandbox.start_link()
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link()
    Riverside.IO.Random.Sandbox.mode(:real)

    Riverside.Stats.start_link()

    {:ok, pid} = TestServer.start(TestEchoHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  test "echo" do
    {:ok, client} = TestClient.start_link(host: "localhost", port: 3000, path: "/")

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
  end
end
