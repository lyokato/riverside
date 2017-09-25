defmodule Riverside.Test.TestServer do

  @spec start(handelr :: module,
              port    :: non_neg_integer,
              path    :: String.t) :: {:ok, pid}
  def start(handler, port, path) do
    :cowboy.start_http(:http, 100,
      [ {:port, port} ],
      [ {:env, [ {:dispatch, dispatch(handler, path)} ] } ])
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
    :cowboy.stop_listener(:http)
    Process.exit(pid, :shutdown)
  end
end
