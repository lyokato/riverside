defmodule HelloRiverside.Handler do
  use Riverside, otp_app: :hello_riverside

  @impl Riverside
  def handle_message(msg, session, state) do
    deliver_me(msg)
    {:ok, session, state}
  end
end
