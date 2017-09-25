defmodule Riverside.ClientTest do

  use ExUnit.Case

  alias Riverside.Test.TestServer
  alias Riverside.Test.TestClient

  setup do

    Riverside.IO.Timestamp.Sandbox.start_link
    Riverside.IO.Timestamp.Sandbox.mode(:real)

    Riverside.IO.Random.Sandbox.start_link
    Riverside.IO.Random.Sandbox.mode(:real)

    {:ok, pid} = TestServer.start(TestHandler, 3000, "/")

    ExUnit.Callbacks.on_exit(fn ->
      Riverside.Test.TestServer.stop(pid)
    end)

    :ok
  end

  test "client" do
    {:ok, client1} = connect_client()
    {:ok, client2} = connect_client()

    TestClient.test_message(%{
      sender: client1,
      message: %{"to" => "foo"},
      receivers: []
    })

    TestClient.stop(client1)
    TestClient.stop(client2)
  end


  defp connect_client() do
    TestClient.start_link(host: "localhost", port: 3000, path: "/")
  end

end
