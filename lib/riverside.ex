defmodule Riverside do

  alias Riverside.Session
  alias Riverside.Authenticator

  defmodule Behaviour do

    @callback __handle_authentication__(req :: :cowboy_req.req)
      :: Authenticator.auth_result

    @callback __connection_timeout__() :: non_neg_integer

    @callback __handle_data__(frame_type :: Riverside.Codec.frame_type,
                              message :: binary,
                              session :: Session.t,
                              state :: any)
      :: {:ok, Session.t}
       | {:error, :invalid_message | :unsupported }

    @callback authenticate(cred_type :: Authenticator.cred_type, params :: map)
      :: Authenticator.callback_result

    @callback init(session :: Session.t, state :: any)
      :: {:ok, Session.t, any}
       | {:error, any}

    @callback handle_message(message :: any, session :: Session.t, state :: any)
      :: {:ok, Session.t, any}

    @callback handle_info(info :: any, session :: Session.t, state :: any)
      :: {:ok, Session.t}

    @callback terminate(session :: Session.t, state :: any)
      :: :ok

  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do

      require Logger

      @behaviour Riverside.Behaviour

      @auth_type Keyword.get(opts, :authentication, :default)
      @connection_timeout Keyword.get(opts, :connection_timeout, 120_000)
      @codec Application.get_env(:riverside, :codec, Riverside.Codec.Json)

      import Riverside.LocalDelivery, only: [
        join_channel: 1,
        leave_channel: 1
      ]

      import Riverside.Session, only: [trap_exit: 2]

      @impl true
      def __connection_timeout__, do: @connection_timeout

      @impl true
      def __handle_authentication__(req) do

        params = Riverside.Util.CowboyUtil.query_map(req)

        __start_authentication__(@auth_type, params, req)

      end

      defp __start_authentication__(:default, params, req) do

        Logger.debug "WebSocket - Default Authentication"

        Riverside.Authenticator.Default.authenticate(req, [],
          &(authenticate(&1, params)))
      end

      defp __start_authentication__({:bearer_token, realm}, params, req) do

        Logger.debug "WebSocket - BearerToken Authentication"

        Riverside.Authenticator.BearerToken.authenticate(req, [realm: realm],
          &(authenticate(&1, params)))
      end

      defp __start_authentication__({:basic, realm}, params, req) do

        Logger.debug "WebSocket - Basic Authentication"

        Riverside.Authenticator.Basic.authenticate(req, [realm: realm],
          &(authenticate(&1, params)))
      end

      defp __start_authentication__(cred, _params, req) do

        Logger.warn "Unsupported authentication credential: #{inspect cred}"

        {:error, :invalid_request, req}

      end

      def __handle_data__(frame_type, data, session, state) do

        if @codec.frame_type === frame_type do

          case @codec.decode(data) do

            {:ok, message} ->
              handle_message(message, session, state)

            {:error, _reason} ->
              {:error, :invalid_message}

          end

        else

          Logger.debug "#{state} unsupported frame type: #{frame_type}"

          {:error, :unsupported}

        end

      end

      @spec deliver(Riverside.LocalDelivery.destination,
                    {Riverside.Codec.frame_type, binary}) :: :ok | :error
      def deliver(dest, {frame_type, message}) do
        Riverside.LocalDelivery.deliver(dest, {frame_type, message})
        :ok
      end

      @spec deliver(Riverside.LocalDelivery.destination, any) :: :ok | :error

      def deliver(dest, data) do
        case @codec.encode(data) do

          {:ok, value} ->
            deliver(dest, {@codec.frame_type, value})

          {:error, :invalid_messsage} ->
            :error

        end
      end

      @spec deliver_me(frame_type :: Riverside.Codec.frame_type,
                       message :: binary) :: :ok | :error

      def deliver_me(frame_type, message) do
        send(self(), {:deliver, frame_type, message})
        :ok
      end

      @spec deliver_me(any) :: :ok | :error

      def deliver_me(data) do
        case @codec.encode(data) do

          {:ok, value} ->
            deliver_me(@codec.frame_type, value)

          {:error, :invalid_messsage} ->
            :error
        end
      end

      @spec close() :: no_return
      def close(), do: send(self(), :stop)

      @impl true
      def authenticate(_cred, _queries), do: {:error, :invalid_request}

      @impl true
      def init(session, state), do: {:ok, session, state}

      @impl true
      def handle_info(event, session, state), do: {:ok, session, state}

      @impl true
      def handle_message(_msg, session, state), do: {:ok, session, state}

      @impl true
      def terminate(_session, _state), do: :ok

      defoverridable [
        authenticate: 2,
        init: 2,
        handle_info: 3,
        handle_message: 3,
        terminate: 2
      ]

    end
  end

end
