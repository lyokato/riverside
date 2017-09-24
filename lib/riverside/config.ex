defmodule Riverside.Config do

  def load(handler, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, handler, [])
    config
  end

  def transmission_limit(config) do
    if Keyword.has_key?(config, :transmission_limit) do
      mc = Keyword.get(config, :transmission_limit, [])
      duration = Keyword.get(mc, :duration, 2_000)
      capacity = Keyword.get(mc, :capacity, 50)
      [duration: duration, capacity: capacity]
    else
      [duration: 2_000, capacity: 50]
    end
  end

end
