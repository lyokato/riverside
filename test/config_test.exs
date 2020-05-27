defmodule Riverside.PortConfigTest do
  use ExUnit.Case

  use Plug.Test

  test "port_config" do
    assert Riverside.Config.get_port(8080) == 8080

    # integer convertible value
    assert Riverside.Config.get_port("8080") == 8080

    assert_raise ArgumentError, fn ->
      assert Riverside.Config.get_port("NOT_CONVERTIBLE")
    end

    # default value is picked
    assert Riverside.Config.get_port({:system, "TEST_PORT", 8080}) == 8080

    temp = System.get_env("TEST_PORT")
    System.put_env("TEST_PORT", "3000")
    assert Riverside.Config.get_port({:system, "TEST_PORT", 80}) == 3000

    System.put_env("TEST_PORT", "INVALID_TYPE")

    assert_raise ArgumentError, fn ->
      Riverside.Config.get_port({:system, "TEST_PORT", 80})
    end

    assert_raise ArgumentError, fn ->
      Riverside.Config.get_port({:system, "OTHER_PORT", "INVALID_TYPE"})
    end

    System.put_env("TEST_PORT", temp)
  end
end
