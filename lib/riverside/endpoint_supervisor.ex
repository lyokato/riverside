defmodule Riverside.EndpointSupervisor do
  use Supervisor
  alias Riverside.Config

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

    scheme =
      if Config.get_tls(handler.__config__.tls) do
        :https
      else
        :http
      end

    [
      {
        Plug.Cowboy,
        [
          scheme: scheme,
          plug: router,
          options: cowboy_opts(router, handler)
        ]
      }
    ]
  end

  defp cowboy_opts(router, module) do
    Config.ensure_module_loaded(module)

    port = Config.get_port(module.__config__.port)
    extra_opts = Config.get_cowboy_opts(module.__config__.cowboy_opts)
    path = module.__config__.path
    idle_timeout = module.__config__.idle_timeout

    cowboy_opts =
      [
        port: port,
        dispatch: dispatch_opts(module, router, path),
        protocol_options: [{:idle_timeout, idle_timeout}]
      ] ++ extra_opts

    cowboy_opts =
      if module.__config__.reuse_port do
        cowboy_opts ++ [{:raw, 1, 15, <<1, 0, 0, 0>>}]
      else
        cowboy_opts
      end

    if Config.get_tls(module.__config__.tls) do
      cowboy_opts ++
        [
          otp_app: module.__config__.otp_app,
          certfile: Config.get_tls_certfile(module.__config__.tls_certfile),
          keyfile: Config.get_tls_keyfile(module.__config__.tls_keyfile)
        ]
    else
      cowboy_opts
    end
  end

  defp dispatch_opts(module, router, path) do
    [
      {:_,
       [
         {path, Riverside.Connection, [handler: module]},
         {:_, Plug.Cowboy.Handler, {router, []}}
       ]}
    ]
  end
end
