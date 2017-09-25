defmodule Riverside.IO.Timestamp.Sandbox do

  @behaviour Riverside.IO.Timestamp.Behaviour

  require Logger

  use GenServer
  alias Riverside.IO.Timestamp.Real

  @type mode :: :fixture | :real

  defstruct stack: [],
            mode: :fixture

  def mode(mode) do
    GenServer.call(__MODULE__, {:set_mode, mode})
  end

  def seconds() do
    {:ok, seconds} = GenServer.call(__MODULE__, :get_seconds)
    Logger.debug "[Sandbox] Timestamp.seconds/0 returns: #{seconds}"
    seconds
  end

  def milli_seconds() do
    {:ok, milli_seconds} = GenServer.call(__MODULE__, :get_milli_seconds)
    Logger.debug "[Sandbox] Timestamp.milli_seconds/0 returns: #{milli_seconds}"
    milli_seconds
  end

  def set_seconds(list) when is_list(list) do
    Logger.debug "[Sandbox] Timestamp refreshes to #{inspect list}"
    GenServer.call(__MODULE__, {:set_seconds_list, list})
  end
  def set_seconds(seconds)do
    set_seconds([seconds])
  end

  def set_milli_seconds(list) when is_list(list) do
    Logger.debug "[Sandbox] Timestamp refreshes to #{inspect list}"
    GenServer.call(__MODULE__, {:set_milli_seconds_list, list})
  end
  def set_milli_seconds(milli_seconds) do
    set_milli_seconds([milli_seconds])
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) when is_list(opts) do
    {:ok, %__MODULE__{stack: opts, mode: :fixture}}
  end

  def handle_call({:set_mode, mode}, _from, state) do
    {:reply, :ok, %{state| mode: mode}}
  end

  def handle_call(:get_seconds, _from, %{mode: :real}=state) do
    {:reply, {:ok, Real.seconds()}, state}
  end
  def handle_call(:get_seconds, _from, %{stack: stack}=state) do
    {ms, stack2} = shift_stack(stack)
    {:reply, {:ok, div(ms, 1_000)}, %{state| stack: stack2}}
  end
  def handle_call(:get_milli_seconds, _from, %{mode: :real}=state) do
    {:reply, {:ok, Real.milli_seconds()}, state}
  end
  def handle_call(:get_milli_seconds, _from, %{stack: stack}=state) do
    {ms, stack2} = shift_stack(stack)
    {:reply, {:ok, ms}, %{state| stack: stack2}}
  end

  def handle_call({:set_seconds_list, list}, _from, state) do
    stack = list |> Enum.map(&:erlang.*(&1, 1_000))
    {:reply, :ok, %{state| stack: stack}}
  end
  def handle_call({:set_milli_seconds_list, stack}, _from, state) do
    {:reply, :ok, %{state| stack: stack}}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp shift_stack([]) do
    raise "No more dummy timestamp data, set enough amount of them"
  end
  defp shift_stack([first|rest]) do
    {first, rest}
  end

end
