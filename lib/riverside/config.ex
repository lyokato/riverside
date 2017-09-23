defmodule Riverside.Config do

  def load(handler, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, handler, [])
    config
  end

  def message_counter_opts(config) do
    if Keyword.has_key?(config, :message_counter) do
      mc = Keyword.get(config, :message_counter, [])
      duration = Keyword.get(mc, :duration, 2_000)
      capacity = Keyword.get(mc, :capacity, 50)
      [duration: duration, capacity: capacity]
    else
      [duration: 2_000, capacity: 50]
    end
  end

end
