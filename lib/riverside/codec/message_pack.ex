defmodule Riverside.Codec.MessagePack do

  @behaviour Riverside.Codec

  @impl Riverside.Codec
  def frame_type do
    :binary
  end

  @impl Riverside.Codec
  def encode(msg) do
    case Msgpax.pack(msg) do

      {:ok, value} ->
        {:ok, value}

      {:error, _exception} ->
        {:error, :invalid_message}

    end
  end

  @impl Riverside.Codec
  def decode(data) do
      case Msgpax.unpack(data) do

        {:ok, value} ->
          {:ok, value}

        {:error, _exception} ->
          {:error, :invalid_message}

      end
  end

end
