defmodule HelloRiversideTest do
  use ExUnit.Case
  doctest HelloRiverside

  test "greets the world" do
    assert HelloRiverside.hello() == :world
  end
end
