defmodule TestAuthBearerTokenHandler do

  require Logger
  use Riverside, otp_app: :riverside

  @impl Riverside
  def authenticate(req) do
    if req.bearer_token == "valid_example" do
      {:ok, 1, %{}}
    else
      error = auth_error_with_code(401)
            |> put_auth_error_bearer_header("example.org")
      {:error, error}
    end
  end

  @impl Riverside
  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end

end

defmodule Riverside.Auth.BearerTokenTest do

  use ExUnit.Case

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do

    Riverside.IO.Timestamp.Sandbox.start_link
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link
    Riverside.IO.Random.Sandbox.mode(:real)

    Riverside.MetricsInstrumenter.setup()

    {:ok, pid} = TestServer.start(TestAuthBearerTokenHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  test "authenticate with bad type authorization header" do
    {:error, {code, _desc}} = TestClient.connect("localhost", 3000, "/", [{:authorization, "Basic xxxx"}])
    assert code == 401
  end

  test "authenticate with bad token" do
    {:error, {code, _desc}} = TestClient.connect("localhost", 3000, "/", [{:authorization, "Bearer bad_token"}])
    assert code == 401
  end

  test "authenticate with correct token" do

    {:ok, client} = TestClient.start_link(host: "localhost",
                                          port: 3000,
                                          path: "/",
                                          headers: [{:authorization, "Bearer valid_example"}])

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

  end

end
