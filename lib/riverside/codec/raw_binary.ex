defmodule Riverside.Codec.RawBinary do

  @behaviour Riverside.Codec

  require Logger

  @impl Riverside.Codec
  def frame_type do
    :binary
  end

  @impl Riverside.Codec
  def encode(msg), do: {:ok, msg}

  @impl Riverside.Codec
  def decode(data), do: {:ok, data}

end
