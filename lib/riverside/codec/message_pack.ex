defmodule Riverside.Codec.MessagePack do

  @behaviour Riverside.Codec

  require Logger

  @impl true
  def frame_type do
    :binary
  end

  @impl true
  def encode(msg) do
    case Msgpax.pack(msg) do

      {:ok, value} ->
        {:ok, value}

      {:error, exception} ->
        Logger.debug "MessagePack: failed to encode: #{inspect exception}"
        {:error, :invalid_message}

    end
  end

  @impl true
  def decode(data) do
      case Msgpax.unpack(data) do

        {:ok, value} ->
          {:ok, value}

        {:error, exception} ->
          Logger.debug "MessagePack: failed to decode: #{inspect exception}"
          {:error, :invalid_message}

      end
  end

end
