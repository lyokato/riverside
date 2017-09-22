defmodule Example.Session do

  require Logger

  use Riverside,
    authentication: {:basic, "exmaple.org"},
    connection_timeout: 60_000

  def authenticate({:basic, username, password}, _queries, stash) do

    Logger.debug "authenticate - basic #{username}:#{password}"

    {:ok, String.to_integer(username), stash}

  end
  def authenticate(cred, _queries, _stash) do

    Logger.debug "Session: unsupported authentication #{cred}"

    {:error, :invalid_request}

  end

  def init(state) do

    Logger.debug "#{state}: init"

    {:ok, state}

  end

  def handle_message(msg, state) do

    Logger.debug "#{state} message: #{inspect msg}"

    Logger.debug "just echo"

    deliver({:session, state.user_id, state.id},
            {:text, Poison.encode!(msg)})

    {:ok, state}

  end

  def terminate(_state) do
    :ok
  end

end
