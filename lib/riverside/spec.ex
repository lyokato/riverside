defmodule Riverside.Spec do

  @doc """
  children(opts)

  Create a list of spec to supervise.

  ## Usage

  ```
  children = Riverside.Spec.children([session: Example.Session,
                                      port: 3000,
                                      path: "/",
                                      reuse_port: false])

  Supervisor.start_link(children, opts)
  ```

  ## Arguments

  pass Keyword list includes following values.

  * session (required): Session module
  * port (optional): port number on which websocket server use. set 3000 as default.
  * path (optional) : WebSocket endpoint URL path. set "/" as default.
  * reuse_port(optional): set false as default

  """

  @spec children(keyword) :: list
  def children(opts) do

    import Supervisor.Spec, warn: false

    [
      worker(Riverside.Stats, []),

      supervisor(Riverside.Supervisor,[opts]),

      worker(GracefulStopper.Plug,
        [[timeout: 0, endpoint: Riverside.Supervisor]],
         [shutdown: 10_000]
       )
    ]

  end

end
