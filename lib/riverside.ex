defmodule Riverside do

  @moduledoc ~S"""
  Handler specification for your WebSocket service.
  """

  alias Riverside.AuthRequest
  alias Riverside.Session

  defmodule Behaviour do

    @type terminate_reason :: {:normal, :shutdown | :timeout}
                            | {:remote, :closed}
                            | {:remote, :cowboy_websocket.close_code, binary}
                            | {:error, :badencoding | :badframe | :closed | :too_many_massages | :over_age | atom}

    @callback __handle_authentication__(req :: AuthRequest.t)
      :: {:ok, Session.user_id, any}
       | {:ok, Session.user_id, Session.session_id, any}
       | {:error, Riverside.AuthError.t}

    @callback __config__() :: map

    @callback __handle_data__(frame_type :: Riverside.Codec.frame_type,
                              message    :: binary,
                              session    :: Session.t,
                              state      :: any)
      :: {:ok, Session.t}
       | {:error, :invalid_message | :unsupported }

    @callback authenticate(req :: AuthRequest.t)
      :: {:ok, Session.user_id, any}
      :: {:ok, Session.user_id, Session.session_id, any}
       | {:error, Riverside.AuthError.t}

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
      :: {:ok, Session.t, any}

    @callback terminate(reason  :: terminate_reason,
                        session :: Session.t,
                        state   :: any)
      :: :ok

  end

  defmacro __using__(opts \\ []) do
    quote location: :keep, bind_quoted: [opts: opts] do

      require Logger

      @behaviour Riverside.Behaviour

      @riverside_config Riverside.Config.load(__MODULE__, opts)

      import Riverside.LocalDelivery, only: [
        join_channel: 1,
        leave_channel: 1
      ]

      import Riverside.AuthError, only: [
        auth_error_with_code: 1,
        put_auth_error_header: 3,
        put_auth_error_basic_header: 2,
        put_auth_error_bearer_header: 2,
        put_auth_error_bearer_header: 3,
      ]

      import Riverside.Session, only: [trap_exit: 2]

      @impl Riverside.Behaviour
      def __config__, do: @riverside_config

      @impl Riverside.Behaviour
      def __handle_authentication__(req) do
        authenticate(req)
      end

      @impl Riverside.Behaviour
      def __handle_data__(frame_type, data, session, state) do

        if @riverside_config.codec.frame_type === frame_type do

          case @riverside_config.codec.decode(data) do

            {:ok, message} ->
              handle_message(message, session, state)

            {:error, _reason} ->
              {:error, :invalid_message}

          end

        else

          if @riverside_config.show_debug_logs do
            Logger.debug "<Riverside.Connection:#{inspect self()}>(#{session}) unsupported frame type: #{frame_type}"
          end

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
        case @riverside_config.codec.encode(data) do

          {:ok, value} ->
            deliver(dest, {@riverside_config.codec.frame_type, value})

          {:error, :invalid_messsage} ->
            :error

        end
      end

      @spec deliver_user(user_id :: Session.user_id,
                         data    :: any) :: :ok | :error

      def deliver_user(user_id, data) do
        deliver({:user, user_id}, data)
      end

      @spec deliver_session(user_id    :: Session.user_id,
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
        case @riverside_config.codec.encode(data) do

          {:ok, value} ->
            deliver_me(@riverside_config.codec.frame_type, value)

          {:error, :invalid_messsage} ->
            :error
        end
      end

      @spec close() :: no_return
      def close(), do: send(self(), :stop)

      @impl Riverside.Behaviour
      def authenticate(req) do
        user_id    = Riverside.IO.Random.bigint()
        session_id = Riverside.IO.Random.hex(20)
        {:ok, user_id, session_id, %{}}
      end

      @impl Riverside.Behaviour
      def init(session, state), do: {:ok, session, state}

      @impl Riverside.Behaviour
      def handle_info(event, session, state), do: {:ok, session, state}

      @impl Riverside.Behaviour
      def handle_message(_msg, session, state), do: {:ok, session, state}

      @impl Riverside.Behaviour
      def terminate(_reason, _session, _state), do: :ok

      defoverridable [
        authenticate: 1,
        init: 2,
        handle_info: 3,
        handle_message: 3,
        terminate: 3
      ]

    end
  end

  def child_spec(args) do
    Riverside.Supervisor.child_spec(args)
  end

end
