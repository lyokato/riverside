defmodule TestAuthQueryHandler do
  require Logger
  use Riverside, otp_app: :riverside

  @impl Riverside
  def authenticate(req) do
    if req.queries["user"] != nil do
      username = req.queries["user"]

      if username == "valid_example" do
        {:ok, username, %{}}
      else
        error = auth_error_with_code(400)
        {:error, error}
      end
    else
      error = auth_error_with_code(400)
      {:error, error}
    end
  end

  @impl Riverside
  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end
end

defmodule Riverside.Auth.QueryTest do
  use ExUnit.Case

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do
    Riverside.IO.Timestamp.Sandbox.start_link()
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link()
    Riverside.IO.Random.Sandbox.mode(:real)

    Riverside.Stats.start_link()

    {:ok, pid} = TestServer.start(TestAuthQueryHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  test "authenticate with bad query" do
    {:error, {code, _desc}} = TestClient.connect("localhost", 3000, "/?user=invalid", [])
    assert code == 400
  end

  test "authenticate without query" do
    {:error, {code, _desc}} = TestClient.connect("localhost", 3000, "/", [])
    assert code == 400
  end

  test "authenticate with correct query" do
    {:ok, client} =
      TestClient.start_link(host: "localhost", port: 3000, path: "/?user=valid_example")

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
