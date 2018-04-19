defmodule Riverside.Connection do

  @behaviour :cowboy_websocket

  require Logger

  alias Riverside.LocalDelivery
  alias Riverside.PeerAddress
  alias Riverside.Session
  alias Riverside.Stats
  alias Riverside.Util.CowboyUtil
  alias Riverside.ExceptionGuard

  @type shutdown_reason :: :too_many_messages

  @type t :: %__MODULE__{handler:         module,
                         session:         Session.t,
                         shutdown_reason: shutdown_reason,
                         handler_state:   any}

  defstruct handler:         nil,
            session:         nil,
            shutdown_reason: nil,
            handler_state:   nil

  def new(handler, user_id, session_id, peer, handler_state) do
    %__MODULE__{handler:         handler,
                session:         Session.new(user_id, session_id, peer),
                shutdown_reason: nil,
                handler_state:   handler_state}
  end

  def init(req, opts) do

    ExceptionGuard.guard(
      "<Riverside.Connection> init",
      fn -> {:ok, CowboyUtil.response(req, 500, %{})} end,
      fn ->

      peer = PeerAddress.gather(req)

      handler = Keyword.fetch!(opts, :handler)

      if handler.__show_debug_logs__ do
        Logger.debug "<Riverside.Connection> incoming new request: #{peer}"
      end

      if Stats.number_of_current_connections() >= handler.__max_connections__() do

        Logger.warn "<Riverside.Connection> connection number is over limit"

        {:ok, req, {:unset, handler.__show_debug_logs__}}

      else

        auth_req = Riverside.AuthRequest.new(req, peer)

        case handler.__handle_authentication__(auth_req) do

          {:ok, user_id, handler_state} ->
            session_id = Riverside.IO.Random.hex(20)
            state = new(handler, user_id, session_id, peer, handler_state)
            {:cowboy_websocket, req, state}

          {:ok, user_id, session_id, handler_state} ->
            state = new(handler, user_id, session_id, peer, handler_state)
            {:cowboy_websocket, req, state}

          {:error, %Riverside.AuthError{code: code, headers: headers}} ->
            {:ok, CowboyUtil.response(req, code, headers), {:unset, handler.__show_debug_logs__}}

          other ->
            if handler.__show_debug_logs__ do
              Logger.debug "<Riverside.Connection> failed to authenticate by reason: #{inspect other}, shutdown"
            end
            {:ok, CowboyUtil.response(req, 500, %{}), {:unset, handler.__show_debug_logs__}}

        end

      end

    end)

  end

  def websocket_init(state) do

    ExceptionGuard.guard(
      "<Riverside.Connection> websocket_init",
      fn -> {:stop, state} end,
      fn ->

      if state.handler.__show_debug_logs__ do
        Logger.debug "<Riverside.#{state.session}> @init"
      end

      if Stats.number_of_current_connections() >= state.handler.__max_connections__() do

        Logger.warn "<Riverside.Connection> connection number is over limit"

        {:stop, state}

      else

        Process.flag(:trap_exit, true)

        send self(), :post_init

        Stats.countup_connections()

        LocalDelivery.register(state.session.user_id, state.session.id)

        {:ok, state}

      end

    end)

  end

  def websocket_info(:post_init, state) do

    ExceptionGuard.guard(
      "<Riverside.Connection> websocket_info",
      fn -> {:stop, state} end,
      fn ->

      if state.handler.__show_debug_logs__ do
        Logger.debug "<Riverside.#{state.session}> @post_init"
      end

      case state.handler.init(state.session, state.handler_state) do

        {:ok, session2, handler_state2} ->
          state2 = %{state| session: session2, handler_state: handler_state2}
          {:ok, state2, :hibernate}

        {:error, reason} ->
          Logger.info "<Riverside.#{state.session}> failed to initialize: #{inspect reason}"
          {:stop, state}

      end

    end)

  end

  def websocket_info(:stop, state) do

    if state.handler.__show_debug_logs__ do
      Logger.debug "<Riverside.#{state.session}> @stop"
    end

    {:stop, state}
  end

  def websocket_info({:deliver, type, msg}, state) do

    if state.handler.__show_debug_logs__ do
      Logger.debug "<Riverside.#{state.session}> @deliver"
    end

    Stats.countup_outgoing_messages()

    {:reply, {type, msg}, state, :hibernate}
  end

  def websocket_info({:EXIT, pid, reason}, %{session: session}=state) do

    ExceptionGuard.guard(
      "<Riverside.Connection> websocket_info",
      fn -> {:stop, state} end,
      fn ->

      if state.handler.__show_debug_logs__ do
        Logger.debug "<Riverside.#{session}> @exit: #{inspect pid} -> #{inspect self()}"
      end

      if Session.should_delegate_exit?(session, pid) do

        session2 = Session.forget_to_trap_exit(session, pid)

        state2 = %{state| session: session2}

        handler_info({:EXIT, pid, reason}, state2)

      else

        {:stop, state}

      end

    end)

  end

  def websocket_info(event, state) do

    ExceptionGuard.guard(
      "<Riverside.Connection> websocket_info",
      fn -> {:stop, state} end,
      fn ->

      if state.handler.__show_debug_logs__ do
        Logger.debug "<Riverside.#{state.session}> @info: #{inspect event}"
      end

      handler_info(event, state)

    end)

  end

  defp handler_info(event, state) do

    case state.handler.handle_info(event, state.session, state.handler_state) do

      {:ok, session2, handler_state2} ->
        state2 = %{state| session: session2, handler_state: handler_state2}
        {:ok, state2}

      # TODO support reply?
      _other ->
        {:stop, state}
    end

  end

  def websocket_handle(:ping, state) do

    ExceptionGuard.guard(
      "<Riverrise.Connection> websocket_handle",
      fn -> {:stop, state} end,
      fn ->

      if state.handler.__show_debug_logs__ do
        Logger.debug "<Riverside.#{state.session}> @ping"
      end

      handle_frame(:ping, nil, state)

    end)

  end

  def websocket_handle({:binary, data}, state) do

    ExceptionGuard.guard(
      "<Riverside.Connection> websocket_handle",
      fn -> {:stop, state} end,
      fn ->

      if state.handler.__show_debug_logs__ do
        Logger.debug "<Riverside.#{state.session}> @binary"
      end

      handle_frame(:binary, data, state)

    end)

  end

  def websocket_handle({:text, data}, state) do

    ExceptionGuard.guard(
      "<Riverside.Connection> websocket_handle",
      fn -> {:stop, state} end,
      fn ->

      if state.handler.__show_debug_logs__ do
        Logger.debug "<Riverside.#{state.session}> @text"
      end

      handle_frame(:text, data, state)

    end)

  end

  def websocket_handle(event, state) do

    if state.handler.__show_debug_logs__ do
      Logger.debug "<Riverside.#{state.session}> handle: unsupported event #{inspect event}"
    end

    {:ok, state}

  end

  def terminate(reason, _req, {:unset, show_debug_logs}) do
    if show_debug_logs do
      Logger.debug "<Riverside> @terminate: #{inspect reason}"
    end
    :ok
  end
  def terminate(reason, _req, %{shutdown_reason: nil}=state) do

    ExceptionGuard.guard(
      "<Riverside.Connection> terminate",
      fn -> :ok end,
      fn ->

      if state.handler.__show_debug_logs__ do
        Logger.debug "<Riverside.#{state.session}> @terminate: #{inspect reason}"
      end

      state.handler.terminate(reason, state.session, state.handler_state)

      Stats.countdown_connections()

      :ok

    end)

  end
  def terminate(reason, _req, state) do

    ExceptionGuard.guard(
      "<Riverside.Connection> terminate",
      fn -> :ok end,
      fn ->

      if state.handler.__show_debug_logs__ do
        Logger.debug "<Riverside.#{state.session}> @terminate: #{inspect reason}"
      end

      state.handler.terminate(state.shutdown_reason, state.session, state.handler_state)

      Stats.countdown_connections()

      :ok

    end)

  end

  defp handle_frame(type, data, %{handler: handler, session: session}=state) do

    Stats.countup_incoming_messages()

    case Session.countup_messages(session, handler.__transmission_limit__) do

      {:ok, session2} ->
        state2 = %{state| session: session2}
        case handle_data(type, data, state2) do

          {:ok, session3, handler_state3} ->
            state3 = %{state2| session: session3, handler_state: handler_state3}
            {:ok, state3, :hibernate}

          {:error, reason} ->
            if state.handler.__show_debug_logs__ do
              Logger.debug "<Riverside.#{session2}> failed to handle frame_type #{inspect type}: #{inspect reason}"
            end
            {:ok, state2}

        end

      {:error, :too_many_messages} ->
        Logger.warn "<Riverside.#{session}> too many messages: #{Session.peer_address(session)}"
        {:stop, %{state| shutdown_reason: :too_many_messages}}

    end

  end

  defp handle_data(:text, data, state) do
    state.handler.__handle_data__(:text, data, state.session, state.handler_state)
  end
  defp handle_data(:binary, data, state) do
    state.handler.__handle_data__(:binary, data, state.session, state.handler_state)
  end
  defp handle_data(:ping, _data, state) do
    {:ok, state.session, state.handler_state}
  end

end
