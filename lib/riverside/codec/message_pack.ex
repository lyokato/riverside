defmodule Riverside.Codec.MessagePack do

  @behaviour Riverside.Codec

  @impl true
  def frame_type do
    :binary
  end

  @impl true
  def encode(msg) do
    case Msgpax.pack(msg) do

      {:ok, value} ->
        {:ok, value}

      {:error, _exception} ->
        {:error, :invalid_message}

    end
  end

  @impl true
  def decode(data) do
      case Msgpax.unpack(data) do

        {:ok, value} ->
          {:ok, value}

        {:error, _exception} ->
          {:error, :invalid_message}

      end
  end

end
