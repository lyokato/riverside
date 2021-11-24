defmodule Riverside.Config do
  @moduledoc ~S"""
  Helper for config data
  """

  @type t :: %__MODULE__{
          max_connections: non_neg_integer,
          codec: module,
          show_debug_logs: boolean,
          connection_max_age: non_neg_integer,
          port: non_neg_integer,
          path: String.t(),
          idle_timeout: non_neg_integer,
          reuse_port: boolean,
          tls: boolean,
          tls_certfile: String.t(),
          tls_keyfile: String.t(),
          transmission_limit: Keyword.t(),
          otp_app: atom,
          cowboy_opts: keyword()
        }

  defstruct max_connections: 0,
            codec: nil,
            show_debug_logs: false,
            connection_max_age: 0,
            port: 0,
            path: "",
            idle_timeout: 0,
            reuse_port: false,
            tls: false,
            tls_certfile: "",
            tls_keyfile: "",
            transmission_limit: [],
            otp_app: nil,
            cowboy_opts: []

  @doc ~S"""
  Load handler's configuration.
  """
  @spec load(module, any) :: any
  def load(handler, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = otp_app |> Application.get_env(handler, [])

    %__MODULE__{
      max_connections: Keyword.get(config, :max_connections, 65536),
      codec: Keyword.get(config, :codec, Riverside.Codec.JSON),
      show_debug_logs: Keyword.get(config, :show_debug_logs, false),
      connection_max_age: Keyword.get(config, :connection_max_age, :infinity),
      port: Keyword.get(config, :port, 3000),
      path: Keyword.get(config, :path, "/"),
      idle_timeout: Keyword.get(config, :idle_timeout, 60_000),
      reuse_port: Keyword.get(config, :reuse_port, false),
      tls: Keyword.get(config, :tls, false),
      tls_certfile: Keyword.get(config, :tls_certfile, ""),
      tls_keyfile: Keyword.get(config, :tls_keyfile, ""),
      transmission_limit: transmission_limit(config),
      otp_app: otp_app,
      cowboy_opts: Keyword.get(config, :cowboy_opts, [])
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
  Get runtime TLS flag
  """
  @spec get_tls(term) :: boolean
  def get_tls(tls_flag) do
    case tls_flag do
      flag when is_boolean(flag) ->
        flag

      str when is_binary(str) ->
        str == "true"

      {:system, env, default} when is_binary(env) and is_boolean(default) ->
        case System.get_env(env) || default do
          flag when is_boolean(flag) -> flag
          str when is_binary(str) -> str == "true"
          _other -> raise ArgumentError, "'tls' value should be a boolaen"
        end

      _other ->
        raise ArgumentError,
              "'tls' config should be a boolean or a tuple styleed value like {:system, 'ENV_NAME', false}."
    end
  end

  @doc ~S"""
  Get runtime TLS cert file
  """
  @spec get_tls_certfile(term) :: String.t()
  def get_tls_certfile(path) do
    case path do
      str when is_binary(str) ->
        str

      {:system, env, default} when is_binary(env) and is_binary(default) ->
        case System.get_env(env) || default do
          str when is_binary(str) -> str
          _other -> raise ArgumentError, "'tls_certfile' value should be a string"
        end

      _other ->
        raise ArgumentError,
              "'tls_certfile' config should be a string or a tuple styleed value like {:system, 'ENV_NAME', '/path/to/default/certfile'}."
    end
  end

  @doc ~S"""
  Get runtime TLS key file
  """
  @spec get_tls_keyfile(term) :: String.t()
  def get_tls_keyfile(path) do
    case path do
      str when is_binary(str) ->
        str

      {:system, env, default} when is_binary(env) and is_binary(default) ->
        case System.get_env(env) || default do
          str when is_binary(str) -> str
          _other -> raise ArgumentError, "'tls_keyfile' value should be a string"
        end

      _other ->
        raise ArgumentError,
              "'tls_keyfile' config should be a string or a tuple styleed value like {:system, 'ENV_NAME', '/path/to/default/keyfile'}."
    end
  end

  @doc ~S"""
  Get runtime cowboy options
  """
  @spec get_cowboy_opts(term) :: keyword()
  def get_cowboy_opts(nil), do: []
  def get_cowboy_opts(opts) when is_list(opts), do: opts

  def get_cowboy_opts(_) do
    raise ArgumentError,
          "'cowboy_opts' config should be a keyword list of cowboy options, see [Cowboy docs](https://ninenines.eu/docs/en/cowboy/2.5/manual/cowboy_http/)."
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
