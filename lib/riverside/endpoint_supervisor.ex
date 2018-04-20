defmodule Riverside.EndpointSupervisor do

  use Supervisor
  alias Riverside.Config

  @default_port 3000
  @default_path "/"
  @default_timeout 60_000

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    children(opts)
    |> Supervisor.init(strategy: :one_for_one)
  end

  def children(opts) do

    handler = Keyword.fetch!(opts, :handler)
    router = Keyword.get(opts, :router, Riverside.Router)

    [{
      Plug.Adapters.Cowboy2, [
        scheme: :http,
        plug:    router,
        options: cowboy_opts(router, handler, opts)
      ]
    }]

  end

  defp cowboy_opts(router, module, opts) do

    Config.ensure_module_loaded(module)

    port         = Keyword.get(opts, :port, @default_port)
    path         = Keyword.get(opts, :path, @default_path)
    idle_timeout = Keyword.get(opts, :idle_timeout, @default_timeout)

    cowboy_opts = [
      port:             port,
      dispatch:         dispatch_opts(module, router, path),
      protocol_options: [{:idle_timeout, idle_timeout}]
    ]

    if Keyword.get(opts, :reuse_port, false) do
      cowboy_opts ++ [{:raw, 1, 15, <<1, 0, 0, 0>>}]
    else
      cowboy_opts
    end

  end

  defp dispatch_opts(module, router, path) do
    [
      {:_, [
        {path, Riverside.Connection, [handler: module]},
        {:_, Plug.Adapters.Cowboy2.Handler, {router, []}}
      ]}
    ]
  end

end
