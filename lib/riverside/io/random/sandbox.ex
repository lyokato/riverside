defmodule Riverside.IO.Random.Sandbox do

  @behaviour Riverside.IO.Random.Behaviour

  require Logger
  alias Riverside.IO.Random.Real

  use GenServer

  def hex(len) do
    {:ok, hex} = GenServer.call(__MODULE__, {:hex, len})
    Logger.debug "[Sandbox] Random.hex/1 returns: #{hex}"
    hex
  end

  def bigint() do
    {:ok, bigint} = GenServer.call(__MODULE__, :bigint)
    Logger.debug "[Sandbox] Random.bigint/0 returns: #{bigint}"
    bigint
  end

  def uuid() do
    {:ok, uuid} = GenServer.call(__MODULE__, :uuid)
    Logger.debug "[Sandbox] Random.uuid/0 returns: #{uuid}"
    uuid
  end

  def create_and_set_hex(len) do
    hex = Real.hex(len)
    set_hex(hex)
    hex
  end

  def set_hex(list) when is_list(list) do
    Logger.debug "[Sandbox] Random HEX refreshes to #{inspect list}"
    GenServer.call(__MODULE__, {:set_hex_list, list})
  end
  def set_hex(hex) do
    set_hex([hex])
  end

  def create_and_set_bigint() do
    bigint = Real.bigint()
    set_bigint(bigint)
    bigint
  end

  def set_bigint(list) when is_list(list) do
    Logger.debug "[Sandbox] Random BigInt refreshes to #{inspect list}"
    GenServer.call(__MODULE__, {:set_bigint_list, list})
  end
  def set_bigint(bigint) do
    set_bigint([bigint])
  end

  def create_and_set_uuid() do
    uuid = Real.uuid()
    set_uuid(uuid)
    uuid
  end

  def set_uuid(list) when is_list(list) do
    Logger.debug "[Sandbox] Random UUI refreshes to #{inspect list}"
    GenServer.call(__MODULE__, {:set_uuid_list, list})
  end
  def set_uuid(uuid) do
    set_uuid([uuid])
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{hex: [], bigint: [], uuid: []}}
  end

  def handle_call({:set_hex_list, list}, _from, state) do
    {:reply, :ok, %{state| hex: list}}
  end

  def handle_call({:set_bigint_list, list}, _from, state) do
    {:reply, :ok, %{state| bigint: list}}
  end

  def handle_call({:set_uuid_list, list}, _from, state) do
    {:reply, :ok, %{state| uuid: list}}
  end

  def handle_call({:hex, _len}, _from, %{hex: stack}=state) do
    {hex, stack2} = shift_stack(stack)
    {:reply, {:ok, hex}, %{state| hex: stack2}}
  end

  def handle_call(:bigint, _from, %{bigint: stack}=state) do
    {bigint, stack2} = shift_stack(stack)
    {:reply, {:ok, bigint}, %{state| bigint: stack2}}
  end

  def handle_call(:uuid, _from, %{uuid: stack}=state) do
    {uuid, stack2} = shift_stack(stack)
    {:reply, {:ok, uuid}, %{state| uuid: stack2}}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp shift_stack([]) do
    raise "No more dummy data, set enough amount of them"
  end
  defp shift_stack([first|rest]) do
    {first, rest}
  end

end
