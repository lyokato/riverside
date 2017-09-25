ExUnit.start()

defmodule TestHandler do

  require Logger
  use Riverside, otp_app: :riverside

  def authenticate(cred, params, header, peer) do
    Logger.debug "auth #{inspect cred}"
    {:ok, 1, %{}}
  end

  def handle_message(msg, session, state) do
    Logger.debug "handle message"
    {:ok, session, state}
  end

  def terminate(session, state) do
    Logger.debug "terminate"
    :ok
  end

end
