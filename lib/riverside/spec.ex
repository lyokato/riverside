defmodule Riverside.Spec do

  @moduledoc ~S"""
  This module provides a function to create a spec list
  for your Supervisor
  """

  @doc ~S"""

  Create a list of spec to supervise.

  ## Usage

  ```
  children = Riverside.Spec.children(Example.Session,
                                      port: 3000,
                                      path: "/",
                                      reuse_port: false)

  Supervisor.start_link(children, opts)
  ```

  ## Arguments

  First argument is module session which implements Riverside.Behaviour

  Second is keyword list includes following parameters.

  * port: port number on which websocket server use. (default: 3000)
  * path: WebSocket endpoint URL path. (default: "/")
  * reuse_port: Boolean flag for TCP SO_REUSEPORT option. (default: false)
  * router: Plug router. (default Riverside.Router)

  """

  @spec children(module, keyword) :: list
  def children(session_module, opts \\ []) do

    import Supervisor.Spec, warn: false

    [
      worker(Riverside.Stats, []),

      supervisor(Riverside.Supervisor, [[session_module, opts]]),

      worker(GracefulStopper.Plug,
        [[timeout: 0, endpoint: Riverside.Supervisor]],
         [shutdown: 10_000]
       )
    ]

  end

end
