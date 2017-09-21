defmodule Riverside.Connection do

  @behaviour :cowboy_websocket_handler

  require Logger

  alias Riverside.Authenticator
  alias Riverside.LocalDelivery
  alias Riverside.MessageDecoder.JsonDecoder
  alias Riverside.PeerInfo
  alias Riverside.Session.State
  alias Riverside.Stats

  @auth_type Application.get_env(:riverside, :authentication, :default)
  @decoder Application.get_env(:riverside, :message_decoder, JsonDecoder)
  @session Application.get_env(:riverside, :session_module)

  @default_timeout 120_000

  @type auth_type :: :none
                   | :default
                   | {:bearer_token, String.t}
                   | {:basic, String.t}

  def init(_, req, _opts) do

    peer = PeerInfo.gather(req)

    Logger.info "WebSocket - incoming new request: #{peer}"

    {queries, _} = :cowboy_req.qs_vals(req)
    params = queries |> Map.new(&{String.to_atom(elem(&1,0)), elem(&1,1)})

    case handle_authentication(@auth_type, params, req) do

      {:ok, user_id, stash} ->
        state = State.new(user_id, peer, stash)
        {:upgrade, :protocol, :cowboy_websocket, req, state}

      {:error, :bad_request, req2} ->
        Logger.info "WebSocket - failed to authenticate, shutdown"
        {:shutdown, req2, nil}

      {:error, :unauthorized, req2} ->
        Logger.info "WebSocket - failed to authenticate, shutdown"
        {:shutdown, req2, nil}

    end
  end

  def websocket_init(_type, req, state) do

    Logger.info "#{state} setup"

    Process.flag(:trap_exit, true)

    send self(), :post_init

    Stats.countup_connections()

    LocalDelivery.register(state.user_id, state.id)

    timeout = Application.get_env(:riverside, :connection_timeout, @default_timeout)

    {:ok, :cowboy_req.compact(req), state, timeout, :hibernate}

  end

  def websocket_info(:post_init, req, state) do

    Logger.debug "#{state} info: post_init"

    case @session.init(state) do

      {:ok, state2} ->
        {:ok, req, state2, :hibernate}

      {:error, reason} ->
        Logger.info "#{state} failed to initialize: #{inspect reason}"
        {:shutdown, req, state}

    end

  end

  def websocket_info(:stop, req, state) do

    Logger.debug "#{state} info: stop"

    {:shutdown, req, state}
  end

  def websocket_info({:deliver, type, msg}, req, state) do

    Logger.debug "#{state} info: deliver"

    {:reply, {type, msg}, req, state, :hibernate}
  end

  def websocket_info({:EXIT, pid, _reason}, req, state) do

    Logger.debug "#{state} info: EXIT <FROM:#{inspect pid}> to <SELF:#{inspect self()}>"

    {:shutdown, req, state}

  end

  def websocket_info(event, req, state) do

    Logger.info "#{state} info: unsupported event #{inspect event}"

    {:ok, req, state}

  end

  def websocket_handle({:ping, data}, req, state) do

    Logger.debug "#{state} incoming PING frame"

    handle_frame(req, :ping, data, state)

  end

  def websocket_handle({:binary, data}, req, state) do

    Logger.debug "#{state} incoming BINARY frame"

    handle_frame(req, :binary, data, state)

  end

  def websocket_handle({:text, data}, req, state) do

    Logger.debug "#{state} incoming TEXT frame"

    handle_frame(req, :text, data, state)

  end

  def websocket_handle(event, req, state) do

    Logger.debug "#{state} handle: unsupported event #{inspect event}"

    {:ok, req, state}

  end

  def websocket_terminate(reason, _req, state) do

    Logger.info "#{state} :terminate #{inspect reason}"

    @session.terminate(state)

    Stats.countdown_connections()

    :ok

  end

  defp handle_frame(req, frame_type, data, state) do

    Stats.countup_messages()

    case State.countup_messages(state) do

      {:ok, state2} ->
        case handle_data(frame_type, data, state2) do

          {:ok, state3} -> {:ok, req, state3}

          {:error, reason} ->
            Logger.info "#{state2} failed to handle frame: #{inspect reason}"
            {:ok, req, state2}

        end

      {:error, :too_many_messages} ->
        Logger.warn "#{state} too many messages: #{State.peer_address(state)}"
        {:shutdown, req, state}

    end

  end

  defp handle_data(:ping, _data, _state) do
    :ok
  end

  defp handle_data(frame_type, data, state) do

    if @decoder.supports_frame_type?(frame_type) do

      case @decoder.decode(data) do

        {:ok, message} ->
          @session.handle_message(message, state)

        {:error, _reason} ->
          {:error, :invalid_message}

      end

    else

      Logger.debug "#{state} unsupported frame type: #{frame_type}"

      {:error, :unsupported}

    end

  end

  defp handle_authentication(:none, _params, _req) do

    Logger.debug "WebSocket - None Authentication"

    {:ok, Riverside.IO.Random.bigint(), %{}}
  end

  defp handle_authentication(:default, params, req) do

    Logger.debug "WebSocket - Default Authentication"

    Authenticator.Default.authenticate(req, fn cred ->
      @session.authenticate(cred, params, %{})
    end)

  end

  defp handle_authentication({:bearer_token, realm}, params, req) do

    Logger.debug "WebSocket - BearerToken Authentication"

    Authenticator.BearerToken.authenticate(req, realm, fn cred ->
      @session.authenticate(cred, params, %{})
    end)

  end

  defp handle_authentication({:basic, realm}, params, req) do

    Logger.debug "WebSocket - Basic Authentication"

    #Basic.authenticate(req, realm,
    #  &(@session.authenticate(&1, params, %{})))

    Authenticator.Basic.authenticate(req, realm, fn cred ->
      @session.authenticate(cred, params, %{})
    end)

  end

end
