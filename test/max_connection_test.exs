defmodule TestMaxConnectionHandler do

  require Logger
  use Riverside, otp_app: :riverside

  @impl Riverside.Behaviour
  def authenticate(_req) do
    {:ok, 1, %{}}
  end

  @impl Riverside.Behaviour
  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end

end

defmodule Riverside.MaxConnectionTest do

  use ExUnit.Case

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do

    Riverside.IO.Timestamp.Sandbox.start_link
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link
    Riverside.IO.Random.Sandbox.mode(:real)

    Riverside.Stats.start_link

    {:ok, pid} = TestServer.start(TestMaxConnectionHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  test "over limit connections" do
    result1 = TestClient.start_link(host: "localhost", port: 3000, path: "/")
    assert elem(result1, 0) == :ok
    result2 = TestClient.start_link(host: "localhost", port: 3000, path: "/")
    assert elem(result2, 0) == :error
  end

end
