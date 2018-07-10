defmodule Riverside.IO.Timestamp do

  defmodule Behaviour do
    @callback seconds() :: non_neg_integer
    @callback milli_seconds() :: non_neg_integer
  end

  @impl_mod Application.get_env(:riverside, :timestamp_module, Riverside.IO.Timestamp.Real)

  @behaviour Behaviour

  @impl Behaviour
  def seconds() do
    @impl_mod.seconds()
  end

  @impl Behaviour
  def milli_seconds() do
    @impl_mod.milli_seconds()
  end

end
