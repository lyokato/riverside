defmodule Riverside.MessageDecoder.JsonDecoder do

  @behaviour Riverside.MessageDecoder

  require Logger

  def supports_frame_type?(:text) do
    true
  end
  def supports_frame_type?(_type) do
    false
  end

  def decode(data) do
      case Poison.decode(data) do

        {:ok, value} ->
          {:ok, value}

        {:error, exception} ->
          Logger.debug "JSON failed to decode: #{inspect exception}"
          {:error, :invalid_message}
      end
  end

end
