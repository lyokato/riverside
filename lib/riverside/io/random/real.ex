defmodule Riverside.IO.Random.Real do
  @behaviour Riverside.IO.Random.Behaviour

  def hex(len) do
    SecureRandom.hex(len)
  end

  def bigint() do
    :rand.uniform(9_223_372_036_854_775_808)
  end

  def uuid() do
    UUID.uuid4()
  end
end
