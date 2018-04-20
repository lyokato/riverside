defmodule Riverside.Codec.JSON do

  @behaviour Riverside.Codec

  @impl true
  def frame_type do
    :text
  end

  @impl true
  def encode(msg) do
    case Poison.encode(msg) do

      {:ok, value} ->
        {:ok, value}

      {:error, _exception} ->
        {:error, :invalid_message}

    end
  end

  @impl true
  def decode(data) do
      case Poison.decode(data) do

        {:ok, value} ->
          {:ok, value}

        {:error, _exception} ->
          {:error, :invalid_message}

      end
  end

end
