defmodule Riverside.IO.Random.Real do

  @behaviour Riverside.IO.Random.Behaviour

  def hex(len) do
    SecureRandom.hex(len)
  end

  def bigint() do
    :rand.uniform(9223372036854775808)
  end

  def uuid() do
    UUID.uuid4()
  end

end
