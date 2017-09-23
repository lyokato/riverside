defmodule Example.Session do

  require Logger

  use Riverside,
    authentication: {:basic, "exmaple.org"},
    connection_timeout: 60_000

  def authenticate({:basic, username, password}, _queries) do

    Logger.debug "authenticate - basic #{username}:#{password}"

    {:ok, String.to_integer(username), %{}}

  end
  def authenticate(cred, _queries) do

    Logger.debug "Session: unsupported authentication #{cred}"

    {:error, :invalid_request}

  end

  def init(session, state) do

    Logger.debug "#{session}: init"

    {:ok, session, state}

  end

  def handle_message(msg, session, state) do

    Logger.debug "#{session} message: #{inspect msg}"

    Logger.debug "just echo"

    deliver_me(:text, Poison.encode!(msg))

    {:ok, session, state}

  end

  def terminate(_session, _state) do
    :ok
  end

end
