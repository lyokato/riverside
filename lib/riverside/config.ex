defmodule Riverside.Config do
  @moduledoc ~S"""
  Helper for config data
  """

  @doc ~S"""
  Load handler's configuration.
  """
  @spec load(module, any) :: any
  def load(handler, opts) do
    config =
      Keyword.fetch!(opts, :otp_app)
      |> Application.get_env(handler, [])

    %{
      max_connections: Keyword.get(config, :max_connections, 65536),
      codec: Keyword.get(config, :codec, Riverside.Codec.JSON),
      show_debug_logs: Keyword.get(config, :show_debug_logs, false),
      connection_max_age: Keyword.get(config, :connection_max_age, :infinity),
      port: Keyword.get(config, :port, 3000),
      path: Keyword.get(config, :path, "/"),
      idle_timeout: Keyword.get(config, :idle_timeout, 60_000),
      reuse_port: Keyword.get(config, :reuse_port, false),
      transmission_limit: transmission_limit(config)
    }
  end

  @type port_type :: pos_integer | {atom, String.t(), pos_integer}

  @doc ~S"""
  Get runtime port number from configuration
  """
  @spec get_port(port_type) :: pos_integer
  def get_port(port) do
    case port do
      num when is_integer(num) ->
        num

      str when is_binary(str) ->
        String.to_integer(str)

      {:system, env, default} when is_binary(env) and is_integer(default) ->
        case System.get_env(env) || default do
          num when is_integer(num) -> num
          str when is_binary(str) -> String.to_integer(str)
          _other -> raise ArgumentError, "'port' value should be a number"
        end

      _other ->
        raise ArgumentError,
              "'port' config should be a positive-number or a tuple styleed value like {:system, 'ENV_NAME', 8080}."
    end
  end

  @doc ~S"""
  Pick the TransmissionLimitter's parameters
  from Handlers configuration.
  """
  @spec transmission_limit(any) :: keyword
  def transmission_limit(config) do
    if Keyword.has_key?(config, :transmission_limit) do
      mc = Keyword.get(config, :transmission_limit, [])
      duration = Keyword.get(mc, :duration, 2_000)
      capacity = Keyword.get(mc, :capacity, 50)
      [duration: duration, capacity: capacity]
    else
      [duration: 2_000, capacity: 50]
    end
  end

  @doc ~S"""
  Ensure passed module is compiled already.
  Or else, this function raise an error.
  """
  @spec ensure_module_loaded(module) :: :ok
  def ensure_module_loaded(module) do
    unless Code.ensure_loaded?(module) do
      raise ArgumentError,
            "#{module} not compiled, ensure the name is correct and it's included in project dependencies."
    end

    :ok
  end
end
