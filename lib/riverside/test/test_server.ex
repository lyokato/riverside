defmodule Riverside.Test.TestServer do

  @spec start(handelr :: module,
              port    :: non_neg_integer,
              path    :: String.t) :: {:ok, pid}
  def start(handler, port, path) do
    :cowboy.start_clear(:test_server,
      [{:port, port}],
      %{env: %{
        dispatch: dispatch(handler, path)
      } }
    )
  end

  defp dispatch(handler, path) do
    :cowboy_router.compile([
      {:_, [
        {path, Riverside.Connection, [handler: handler]}
      ]}
    ])
  end

  @spec stop(pid) :: no_return
  def stop(pid) do
    :cowboy.stop_listener(:test_server)
    Process.exit(pid, :shutdown)
  end
end
