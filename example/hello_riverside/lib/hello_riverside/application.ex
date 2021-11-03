defmodule HelloRiverside.Application do
  use Application

  @impl true
  def start(_type, _args) do
    [
      {Riverside, [handler: HelloRiverside.Handler]}
    ]
    |> Supervisor.start_link(
      strategy: :one_for_one,
      name: HelloRiverside.Supervisor
    )
  end
end
