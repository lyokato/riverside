defmodule Riverside.Util.ModuleUtil do

  @spec ensure_loaded(module) :: :ok

  def ensure_loaded(module) do
    unless Code.ensure_loaded?(module) do
      raise ArgumentError, "#{module} not compiled, ensure the name is correct and it's included in project dependencies."
    end
    :ok
  end

end

