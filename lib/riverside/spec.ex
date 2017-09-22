defmodule Riverside.Spec do

  # TODO define type of opts
  def child_spec(opts) do

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
