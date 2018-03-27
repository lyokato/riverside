defmodule TestAuthBasicHandler do

  require Logger
  use Riverside, otp_app: :riverside

  def authenticate({:basic, username, password}, _params, _header, _peer) do
    if username == "valid_example" and password == "foobar" do
      {:ok, username, %{}}
    else
      {:error, :invalid_request}
    end
  end

  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end

end

defmodule Riverside.Auth.BasicTest do

  use ExUnit.Case

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do

    Riverside.IO.Timestamp.Sandbox.start_link
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link
    Riverside.IO.Random.Sandbox.mode(:real)

    Riverside.Stats.start_link

    {:ok, pid} = TestServer.start(TestAuthBasicHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  defp build_token(username, password) do
    Base.encode64("#{username}:#{password}")
  end

  test "authenticate with bad type authorization header" do
    {:error, {code, _desc}} = TestClient.connect("localhost", 3000, "/",
                                                 [{:authorization, "Bearer xxxx"}])
    assert code == 401
  end

  test "authenticate with bad token" do
    {:error, {code, _desc}} = TestClient.connect("localhost", 3000, "/",
                                                 [{:authorization, "Basic bad_token"}])
    assert code == 401
  end

  test "authenticate with bad username" do
    {:error, {code, _desc}} = TestClient.connect("localhost", 3000, "/",
                                                 [{:authorization, "Basic " <> build_token("invalid", "foobar")}])
    assert code == 401
  end

  test "authenticate with bad password" do
    {:error, {code, _desc}} = TestClient.connect("localhost", 3000, "/",
                                                 [{:authorization, "Basic " <> build_token("valid_example", "invalid")}])
    assert code == 401
  end

  test "authenticate with correct token" do

    {:ok, client} = TestClient.start_link(host: "localhost",
                                          port: 3000,
                                          path: "/",
                                          headers: [{:authorization, "Basic " <> build_token("valid_example", "foobar")}])

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
