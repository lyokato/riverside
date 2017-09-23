defmodule Riverside.Config do

  def load(handler, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, handler, [])
    config
  end

end
