defmodule Riverside.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(opts) do
    children(opts)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp children(opts) do
    [
      {Registry, keys: :duplicate, name: Riverside.PubSub},
      Riverside.Stats,
      {Riverside.EndpointSupervisor, opts},
      {TheEnd.AcceptanceStopper,
       [
         timeout: 0,
         endpoint: Riverside.Supervisor,
         gatherer: TheEnd.ListenerGatherer.Plug
       ]}
    ]
  end
end
