defmodule Example.Handler do

  require Logger

  use Riverside, otp_app: :riverside

  def authenticate({:basic, username, password}, _queries) do

    Logger.debug "authenticate - basic #{username}:#{password}"

    {:ok, String.to_integer(username), %{}}

  end

  def init(session, state) do

    Logger.debug "#{session} Handler: init"

    {:ok, session, state}

  end

  def handle_message(msg, session, state) do

    Logger.debug "#{session} Handler: message: #{inspect msg}"

    Logger.debug "just echo"

    deliver_me(msg)

    {:ok, session, state}

  end

  def terminate(session, _state) do

    Logger.debug "#{session} Handler: terminate"
    :ok
  end

end
