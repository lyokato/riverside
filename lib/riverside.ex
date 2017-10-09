defmodule Riverside do

  @moduledoc ~S"""
  Handler specification for your WebSocket service.
  """

  alias Riverside.Authenticator
  alias Riverside.PeerAddress
  alias Riverside.Session

  defmodule Behaviour do

    @type terminate_reason :: {:normal, :shutdown | :timeout}
                            | {:remote, :closed}
                            | {:remote, :cowboy_websocket.close_code, binary}
                            | {:error, :badencoding | :badframe | :closed | :too_many_massages | atom}

    @callback __handle_authentication__(req  :: :cowboy_req.req,
                                        peer :: PeerAddress.t)
      :: Authenticator.auth_result

    @callback __connection_timeout__() :: non_neg_integer

    @callback __transmission_limit__() :: keyword

    @callback __handle_data__(frame_type :: Riverside.Codec.frame_type,
                              message    :: binary,
                              session    :: Session.t,
                              state      :: any)
      :: {:ok, Session.t}
       | {:error, :invalid_message | :unsupported }

    @callback authenticate(cred_type :: Authenticator.cred_type,
                           params    :: map,
                           headers   :: map,
                           peer      :: PeerAddress.t)
      :: Authenticator.callback_result

    @callback init(session :: Session.t, state :: any)
      :: {:ok, Session.t, any}
       | {:error, any}

    @callback handle_message(message :: any,
                             session :: Session.t,
                             state   :: any)
      :: {:ok, Session.t, any}

    @callback handle_info(info    :: any,
                          session :: Session.t,
                          state   :: any)
      :: {:ok, Session.t}

    @callback terminate(reason  :: terminate_reason,
                        session :: Session.t,
                        state   :: any)
      :: :ok

  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do

      require Logger

      @behaviour Riverside.Behaviour

      config = Riverside.Config.load(__MODULE__, opts)

      @auth_type          Keyword.get(config, :authentication, :default)
      @connection_timeout Keyword.get(config, :connection_timeout, 120_000)
      @codec              Keyword.get(config, :codec, Riverside.Codec.JSON)

      @transmission_limit Riverside.Config.transmission_limit(config)

      import Riverside.LocalDelivery, only: [
        join_channel: 1,
        leave_channel: 1
      ]

      import Riverside.Session, only: [trap_exit: 2]

      @impl true
      def __transmission_limit__, do: @transmission_limit

      @impl true
      def __connection_timeout__, do: @connection_timeout

      @impl true
      def __handle_authentication__(req, peer) do

        params  = Riverside.Util.CowboyUtil.queries(req)
        headers = Riverside.Util.CowboyUtil.headers(req)

        __start_authentication__(@auth_type, params, headers, peer, req)

      end

      defp __start_authentication__(:default, params, headers, peer, req) do

        Logger.debug "<Riverside.Connection> Default Authentication"

        Riverside.Authenticator.Default.authenticate(req, [],
          &(authenticate(&1, params, headers, peer)))
      end

      defp __start_authentication__({:bearer_token, realm}, params, headers, peer, req) do

        Logger.debug "<Riverside.Connection> BearerToken Authentication"

        Riverside.Authenticator.BearerToken.authenticate(req, [realm: realm],
          &(authenticate(&1, params, headers, peer)))
      end

      defp __start_authentication__({:basic, realm}, params, headers, peer, req) do

        Logger.debug "<Riverside.Connection> Basic Authentication"

        Riverside.Authenticator.Basic.authenticate(req, [realm: realm],
          &(authenticate(&1, params, headers, peer)))
      end

      defp __start_authentication__(cred, _params, _headers, peer, req) do

        Logger.warn "<Riverside.Connection> Unsupported authentication credential: #{inspect cred}"

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

          Logger.info "<Riverside.#{session}> unsupported frame type: #{frame_type}"

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

      @spec deliver_user(user_id :: Riverside.Session.user_id,
                         data    :: any) :: :ok | :error

      def deliver_user(user_id, data) do
        deliver({:user, user_id}, data)
      end

      @spec deliver_session(user_id    :: Riverside.Session.user_id,
                            session_id :: String.t,
                            data       :: any) :: :ok | :error
      def deliver_session(user_id, session_id, data) do
        deliver({:session, user_id, session_id}, data)
      end

      @spec deliver_channel(channel_id :: any,
                            data       :: any) :: :ok | :error

      def deliver_channel(channel_id, data) do
        deliver({:channel, channel_id}, data)
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
      def authenticate(_cred, _queries, _headers, _peer) do
        {:ok, Riverside.IO.Random.bigint(), %{}}
      end

      @impl true
      def init(session, state), do: {:ok, session, state}

      @impl true
      def handle_info(event, session, state), do: {:ok, session, state}

      @impl true
      def handle_message(_msg, session, state), do: {:ok, session, state}

      @impl true
      def terminate(_reason, _session, _state), do: :ok

      defoverridable [
        authenticate: 4,
        init: 2,
        handle_info: 3,
        handle_message: 3,
        terminate: 3
      ]

    end
  end

end
