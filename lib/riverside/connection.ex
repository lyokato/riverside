defmodule Riverside.Connection do

  @behaviour :cowboy_websocket_handler

  require Logger

  alias Riverside.Authenticator
  alias Riverside.LocalDelivery
  alias Riverside.MessageDecoder.JsonDecoder
  alias Riverside.PeerInfo
  alias Riverside.Session.State
  alias Riverside.Stats
  alias Riverside.Util.CowboyUtil

  @default_timeout 120_000

  def init(_, req, opts) do

    peer = PeerInfo.gather(req)

    Logger.info "WebSocket - incoming new request: #{peer}"

    mod = Keyword.fetch!(opts, :session_module)

    auth_type = Application.get_env(:riverside, :authentication, :default)

    params = CowboyUtil.query_map(req)

    case handle_authentication(auth_type, params, req, mod) do

      {:ok, user_id, stash} ->
        state = State.new(user_id, peer, stash)
        {:upgrade, :protocol, :cowboy_websocket, req, {mod, state}}

      {:error, :bad_request, req2} ->
        Logger.info "WebSocket - failed to authenticate, shutdown"
        {:shutdown, req2, nil}

      {:error, :unauthorized, req2} ->
        Logger.info "WebSocket - failed to authenticate, shutdown"
        {:shutdown, req2, nil}

    end
  end

  def websocket_init(_type, req, {mod, state}) do

    Logger.info "#{state} setup"

    Process.flag(:trap_exit, true)

    send self(), :post_init

    Stats.countup_connections()

    LocalDelivery.register(state.user_id, state.id)

    timeout = Application.get_env(:riverside, :connection_timeout, @default_timeout)

    {:ok, :cowboy_req.compact(req), {mod, state}, timeout, :hibernate}

  end

  def websocket_info(:post_init, req, {mod, state}) do

    Logger.debug "#{state} info: post_init"

    case mod.init(state) do

      {:ok, state2} ->
        {:ok, req, {mod, state2}, :hibernate}

      {:error, reason} ->
        Logger.info "#{state} failed to initialize: #{inspect reason}"
        {:shutdown, req, {mod, state}}

    end

  end

  def websocket_info(:stop, req, {mod, state}) do

    Logger.debug "#{state} info: stop"

    {:shutdown, req, {mod, state}}
  end

  def websocket_info({:deliver, type, msg}, req, {mod, state}) do

    Logger.debug "#{state} info: deliver"

    {:reply, {type, msg}, req, {mod, state}, :hibernate}
  end

  def websocket_info({:EXIT, pid, _reason}, req, {mod, state}) do

    Logger.debug "#{state} info: EXIT <FROM:#{inspect pid}> to <SELF:#{inspect self()}>"

    {:shutdown, req, {mod, state}}

  end

  # TODO support handle_info on session module
  #
  #def websocket_info(event, req, {mod, state}) do

  #  Logger.info "#{state} info: unsupported event #{inspect event}"

  #  case mod.handle_info(event, state) do
  #    {:ok, state2} ->
  #      {:ok, req, {mod, state2}}
  #    # TODO
  #    _other ->
  #      {:shutdown, req, {mod, state}}
  #  end

  #end

  def websocket_handle({:ping, data}, req, {mod, state}) do

    Logger.debug "#{state} incoming PING frame"

    handle_frame(req, :ping, data, {mod, state})

  end

  def websocket_handle({:binary, data}, req, {mod, state}) do

    Logger.debug "#{state} incoming BINARY frame"

    handle_frame(req, :binary, data, {mod, state})

  end

  def websocket_handle({:text, data}, req, {mod, state}) do

    Logger.debug "#{state} incoming TEXT frame"

    handle_frame(req, :text, data, {mod, state})

  end

  def websocket_handle(event, req, {mod, state}) do

    Logger.debug "#{state} handle: unsupported event #{inspect event}"

    {:ok, req, {mod, state}}

  end

  def websocket_terminate(reason, _req, {mod, state}) do

    Logger.info "#{state} :terminate #{inspect reason}"

    mod.terminate(state)

    Stats.countdown_connections()

    :ok

  end

  defp handle_frame(req, frame_type, data, {mod, state}) do

    Stats.countup_messages()

    case State.countup_messages(state) do

      {:ok, state2} ->
        case handle_data(frame_type, data, {mod, state2}) do

          {:ok, state3} -> {:ok, req, {mod, state3}}

          {:error, reason} ->
            Logger.info "#{state2} failed to handle frame: #{inspect reason}"
            {:ok, req, {mod, state2}}

        end

      {:error, :too_many_messages} ->
        Logger.warn "#{state} too many messages: #{State.peer_address(state)}"
        {:shutdown, req, {mod, state}}

    end

  end

  defp handle_data(:ping, _data, {_mod, _state}) do
    :ok
  end

  defp handle_data(frame_type, data, {mod, state}) do

    decoder = Application.get_env(:riverside, :message_decoder, JsonDecoder)

    if decoder.supports_frame_type?(frame_type) do

      case decoder.decode(data) do

        {:ok, message} ->
          mod.handle_message(message, state)

        {:error, _reason} ->
          {:error, :invalid_message}

      end

    else

      Logger.debug "#{state} unsupported frame type: #{frame_type}"

      {:error, :unsupported}

    end

  end

  defp handle_authentication(:default, params, req, mod) do

    Logger.debug "WebSocket - Default Authentication"

    Authenticator.Default.authenticate(req, [], fn cred ->
      mod.authenticate(cred, params, %{})
    end)

  end

  defp handle_authentication({:bearer_token, realm}, params, req, mod) do

    Logger.debug "WebSocket - BearerToken Authentication"

    Authenticator.BearerToken.authenticate(req, [realm: realm], fn cred ->
      mod.authenticate(cred, params, %{})
    end)

  end

  defp handle_authentication({:basic, realm}, params, req, mod) do

    Logger.debug "WebSocket - Basic Authentication"

    Authenticator.Basic.authenticate(req, [realm: realm], fn cred ->
      mod.authenticate(cred, params, %{})
    end)

  end

end
