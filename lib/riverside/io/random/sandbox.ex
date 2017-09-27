defmodule Riverside.IO.Random.Sandbox do

  @behaviour Riverside.IO.Random.Behaviour

  require Logger
  alias Riverside.IO.Random.Real

  use GenServer

  @type mode :: :fixture | :real

  defstruct uuid:   [],
            hex:    [],
            bigint: [],
            mode: :fixture

  def mode(mode) do
    GenServer.call(__MODULE__, {:set_mode, mode})
  end

  def hex(len) do
    {:ok, hex} = GenServer.call(__MODULE__, {:hex, len})
    Logger.debug "<Riverside.Random.Sandbox> hex/1 returns: #{hex}"
    hex
  end

  def bigint() do
    {:ok, bigint} = GenServer.call(__MODULE__, :bigint)
    Logger.debug "<Riverside.Random.Sandbox> bigint/0 returns: #{bigint}"
    bigint
  end

  def uuid() do
    {:ok, uuid} = GenServer.call(__MODULE__, :uuid)
    Logger.debug "<Riverside.Random.Sandbox> uuid/0 returns: #{uuid}"
    uuid
  end

  def create_and_set_hex(len) do
    hex = Real.hex(len)
    set_hex(hex)
    hex
  end

  def set_hex(list) when is_list(list) do
    Logger.debug "<Riverside.Random.Sandbox> hex refreshes to #{inspect list}"
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
    Logger.debug "<Riverside.Random.Sandbox> bigint refreshes to #{inspect list}"
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
    Logger.debug "<Riverside.Random.Sandbox> Random UUI refreshes to #{inspect list}"
    GenServer.call(__MODULE__, {:set_uuid_list, list})
  end
  def set_uuid(uuid) do
    set_uuid([uuid])
  end

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{hex: [], bigint: [], uuid: [], mode: :fixture}}
  end

  def handle_call({:set_mode, mode}, _from, state) do
    {:reply, :ok, %{state| mode: mode}}
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

  def handle_call({:hex, len}, _from, %{mode: :real}=state) do
    {:reply, {:ok, Real.hex(len)}, state}
  end
  def handle_call({:hex, _len}, _from, %{hex: stack}=state) do
    {hex, stack2} = shift_stack(stack)
    {:reply, {:ok, hex}, %{state| hex: stack2}}
  end

  def handle_call(:bigint, _from, %{mode: :real}=state) do
    {:reply, {:ok, Real.bigint()}, state}
  end
  def handle_call(:bigint, _from, %{bigint: stack}=state) do
    {bigint, stack2} = shift_stack(stack)
    {:reply, {:ok, bigint}, %{state| bigint: stack2}}
  end

  def handle_call(:uuid, _from, %{mode: :real}=state) do
    {:reply, {:ok, Real.uuid()}, state}
  end
  def handle_call(:uuid, _from, %{uuid: stack}=state) do
    {uuid, stack2} = shift_stack(stack)
    {:reply, {:ok, uuid}, %{state| uuid: stack2}}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp shift_stack([]) do
    raise "<Riverside.Random.Sandbox> No more dummy data, set enough amount of them"
  end
  defp shift_stack([first|rest]) do
    {first, rest}
  end

end
