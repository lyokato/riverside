defmodule Riverside.Codec.RawText do

  @behaviour Riverside.Codec

  require Logger

  @impl true
  def frame_type do
    :text
  end

  @impl true
  def encode(msg), do: {:ok, msg}

  @impl true
  def decode(data), do: {:ok, data}

end
