defmodule Riverside do

  alias Riverside.State
  alias Riverside.Authenticator

  defmodule Behaviour do

    @callback __authenticate__(:cowboy_req.req)
      :: Authenticator.auth_result

    @callback __connection_timeout__() :: non_neg_integer

    @callback authenticate(Authenticator.cred_type, map, map)
      :: Authenticator.callback_result

    @callback init(State.t)
      :: {:ok, State.t}
       | {:error, any}

    @callback handle_message(any, State.t)
      :: {:ok, State.t}

    @callback terminate(State.t)
      :: :ok

  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do

      require Logger

      @behaviour Riverside.Behaviour

      @auth_type          Keyword.get(opts, :authentication,     :default)
      @connection_timeout Keyword.get(opts, :connection_timeout, 120_000)

      import Riverside.LocalDelivery, only: [
        deliver: 2,
        join_channel: 1,
        leave_channel: 1,
        close: 2
      ]

      @impl true
      def __connection_timeout__ do
        @connection_timeout
      end

      @impl true
      def __authenticate__(req) do
        params = Riverside.Util.CowboyUtil.query_map(req)
        __start_authentication__(@auth_type, params, req)
      end

      defp __start_authentication__(:default, params, req) do
        Logger.debug "WebSocket - Default Authentication"
        Riverside.Authenticator.Default.authenticate(req, [],
          &(authenticate(&1, params, %{})))
      end
      defp __start_authentication__({:bearer_token, realm}, params, req) do
        Logger.debug "WebSocket - BearerToken Authentication"
        Riverside.Authenticator.BearerToken.authenticate(req, [realm: realm],
          &(authenticate(&1, params, %{})))
      end
      defp __start_authentication__({:basic, realm}, params, req) do
        Logger.debug "WebSocket - Basic Authentication"
        Riverside.Authenticator.Basic.authenticate(req, [realm: realm],
          &(authenticate(&1, params, %{})))
      end
      defp __start_authentication__(cred, _params, req) do
        Logger.warn "Unsupported authentication credential: #{inspect cred}"
        {:error, :invalid_request, req}
      end

      @impl true
      def authenticate(_cred, _queries, _stash) do
        {:error, :invalid_request}
      end

      @impl true
      def init(state) do
        {:ok, state}
      end

      @impl true
      def handle_message(_msg, state) do
        {:ok, state}
      end

      @impl true
      def terminate(_state) do
        :ok
      end

      defoverridable [
        authenticate: 3,
        init: 1,
        handle_message: 2,
        terminate: 1
      ]

    end
  end

end
