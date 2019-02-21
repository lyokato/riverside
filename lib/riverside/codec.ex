defmodule Riverside.Codec do
  @type frame_type :: :text | :binary

  @callback frame_type :: frame_type

  @callback decode(binary) ::
              {:ok, any}
              | {:error, :invalid_message}

  @callback encode(any) ::
              {:ok, binary}
              | {:error, :invalid_message}
end
