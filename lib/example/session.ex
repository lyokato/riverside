defmodule Example.Session do

  require Logger
  use Riverside

  def authenticate({:basic, username, password}, _queries, stash) do

    Logger.debug "authenticate - basic #{username}:#{password}"

    {:ok, String.to_integer(username), stash}

  end
  def authenticate(_cred, _queries, _stash) do

    Logger.debug "Session: unsupported authentication "

    {:error, :invalid_request}

  end

  def init(state) do

    Logger.debug "Session: init"

    {:ok, state}

  end

  def handle_message(msg, state) do

    Logger.debug "Session: message"

    Logger.debug "just echo"

    deliver_to_session(state.user_id,
                       state.id,
                       :text,
                       Poison.encode!(msg))

    {:ok, state}

  end

  def terminate(_state) do
    :ok
  end

end
