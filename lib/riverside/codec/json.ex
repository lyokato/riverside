defmodule Riverside.Codec.JSON do

  @behaviour Riverside.Codec

  require Logger

  @impl true
  def frame_type do
    :text
  end

  @impl true
  def encode(msg) do
    case Poison.encode(msg) do

      {:ok, value} ->
        {:ok, value}

      {:error, exception} ->
        Logger.debug "<Riverside.Codec.JSON> failed to encode: #{inspect exception}"
        {:error, :invalid_message}

    end
  end

  @impl true
  def decode(data) do
      case Poison.decode(data) do

        {:ok, value} ->
          {:ok, value}

        {:error, exception} ->
          Logger.debug "<Riverside.Codec.JSON> failed to decode: #{inspect exception}"
          {:error, :invalid_message}

      end
  end

end
