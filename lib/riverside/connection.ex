defmodule Riverside.Connection do

  @behaviour :cowboy_websocket

  require Logger

  alias Riverside.LocalDelivery
  alias Riverside.PeerAddress
  alias Riverside.Session
  alias Riverside.Stats
  alias Riverside.Util.CowboyUtil

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
    try do

      peer = PeerAddress.gather(req)

      Logger.debug "<Riverside.Connection> incoming new request: #{peer}"

      handler = Keyword.fetch!(opts, :handler)

      if Stats.number_of_current_connections() >= handler.__max_connections__() do

        Logger.warn "<Riverside.Connection> connection number is over limit"

        {:ok, req, :unset}

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
            {:ok, CowboyUtil.response(req, code, headers), :unset}

          other ->
            Logger.debug "<Riverside.Connection> failed to authenticate by reason: #{inspect other}, shutdown"
            {:ok, CowboyUtil.response(req, 500, %{}), :unset}

        end

      end

    rescue
      err ->
        Logger.error "<Riverside.Connection> init error: #{inspect err}"
        {:ok, CowboyUtil.response(req, 500, %{}), :unset}

    catch

      error_type, value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> init error: #{errmsg}, #{inspect value}"
        {:ok, CowboyUtil.response(req, 500, %{}), :unset}

    end

  end

  def websocket_init(state) do

    try do

      Logger.debug "<Riverside.#{state.session}> @init"

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

    catch

      error_type, value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> websocket_init error: #{errmsg}, #{inspect value}"
        {:stop, state}

    end

  end

  def websocket_info(:post_init, state) do

    try do

      Logger.debug "<Riverside.#{state.session}> @post_init"

      case state.handler.init(state.session, state.handler_state) do

        {:ok, session2, handler_state2} ->
          state2 = %{state| session: session2, handler_state: handler_state2}
          {:ok, state2, :hibernate}

        {:error, reason} ->
          Logger.info "<Riverside.#{state.session}> failed to initialize: #{inspect reason}"
          {:stop, state}

      end

    catch

      error_type, value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> websocket_init error: #{errmsg}, #{inspect value}"
        {:stop, state}

    end

  end

  def websocket_info(:stop, state) do

    Logger.debug "<Riverside.#{state.session}> @stop"

    {:stop, state}
  end

  def websocket_info({:deliver, type, msg}, state) do

    Logger.debug "<Riverside.#{state.session}> @deliver"

    Stats.countup_outgoing_messages()

    {:reply, {type, msg}, state, :hibernate}
  end

  def websocket_info({:EXIT, pid, reason}, %{session: session}=state) do

    try do

      Logger.debug "<Riverside.#{session}> @exit: #{inspect pid} -> #{inspect self()}"

      if Session.should_delegate_exit?(session, pid) do

        session2 = Session.forget_to_trap_exit(session, pid)

        state2 = %{state| session: session2}

        handler_info({:EXIT, pid, reason}, state2)

      else

        {:stop, state}

      end

    catch

      error_type, value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> websocket_info error: #{errmsg}, #{inspect value}"
        {:stop, state}

    end

  end

  def websocket_info(event, state) do

    try do

      Logger.debug "<Riverside.#{state.session}> @info: #{inspect event}"

      handler_info(event, state)

    catch

      error_type, value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> websocket_info error: #{errmsg}, #{inspect value}"
        {:stop, state}

    end

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

    try do

      Logger.debug "<Riverside.#{state.session}> @ping"

      handle_frame(:ping, nil, state)

    catch

      error_type, _value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> websocket_handle error: #{errmsg}"
        {:stop, state}

    end

  end

  def websocket_handle({:binary, data}, state) do

    try do

      Logger.debug "<Riverside.#{state.session}> @binary"

      handle_frame(:binary, data, state)

    catch

      error_type, _value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> websocket_handle error: #{errmsg}"
        {:stop, state}

    end

  end

  def websocket_handle({:text, data}, state) do

    try do

      Logger.debug "<Riverside.#{state.session}> @text"

      handle_frame(:text, data, state)

    catch

      error_type, _value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> websocket_handle error: #{errmsg}"
        {:stop, state}

    end

  end

  def websocket_handle(event, state) do

    Logger.debug "<Riverside.#{state.session}> handle: unsupported event #{inspect event}"

    {:ok, state}

  end

  def terminate(reason, _req, :unset) do
    Logger.info "<Riverside> @terminate: #{inspect reason}"
    :ok
  end
  def terminate(reason, _req, %{shutdown_reason: nil}=state) do

    try do

      Logger.info "<Riverside.#{state.session}> @terminate: #{inspect reason}"

      state.handler.terminate(reason, state.session, state.handler_state)

      Stats.countdown_connections()

      :ok

    rescue

      err ->
        Logger.error "<Riverside.Connection> terminate error: #{inspect err}"
        :ok

    catch

      error_type, value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> terminate error: #{errmsg}, #{inspect value}"
        :ok

    end

  end
  def terminate(reason, _req, state) do

    try do

      Logger.info "<Riverside.#{state.session}> @terminate: #{inspect reason}"

      state.handler.terminate(state.shutdown_reason, state.session, state.handler_state)

      Stats.countdown_connections()

    rescue

      err ->
        Logger.error "<Riverside.Connection> terminate error: #{inspect err}"
        :ok

    catch

      error_type, value when
        error_type in [:error, :throw, :exit] ->

        errmsg = System.stacktrace()
               |> Exception.format_stacktrace()
        Logger.error "<Riverside.Connection> terminate error: #{errmsg}, #{inspect value}"
        :ok

    end

    :ok
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
            Logger.info "<Riverside.#{session2}> failed to handle frame_type #{inspect type}: #{inspect reason}"
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
