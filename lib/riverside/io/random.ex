defmodule Riverside.IO.Random do

  @impl_mod Application.get_env(:riverside, :random_module, Riverside.IO.Random.Real)

  defmodule Behaviour do
    @callback hex(non_neg_integer) :: String.t
    @callback bigint()             :: non_neg_integer
    @callback uuid()               :: String.t
  end

  @behaviour Behaviour

  def hex(len) do
    @impl_mod.hex(len)
  end

  def bigint() do
    @impl_mod.bigint()
  end

  def uuid() do
    @impl_mod.uuid()
  end

end
