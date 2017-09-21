defmodule Riverside.MessageDecoder do

  @type frame_type :: :text | :binary

  @callback supports_frame_type?(frame_type) :: boolean

  @callback decode(binary) :: {:ok, any}
    | {:error, :invalid_message}

end
