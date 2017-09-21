defmodule Riverside.Stats do

  use GenServer

  defstruct connections: 0,
            messages:    0,
            started_at:  0

  def number_of_connections do
    GenServer.call(__MODULE__, :number_of_connections)
  end
  def number_of_messages do
    GenServer.call(__MODULE__, :number_of_messages)
  end

  def countup_messages do
    GenServer.cast(__MODULE__, :countup_messages)
  end

  def countup_connections do
    GenServer.cast(__MODULE__, :countup_connections)
  end

  def countdown_connections do
    GenServer.cast(__MODULE__, :countdown_connections)
  end

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  defp new() do
    %__MODULE__{connections: 0,
                messages:    0,
                started_at:  Riverside.IO.Timestamp.seconds()}
  end

  def init(_args) do
    {:ok, new()}
  end

  def handle_call(:number_of_connections, _from, state) do
    {:reply, state.connections, state}
  end

  def handle_call(:number_of_messages, _from, state) do
    {:reply, state.messages, state}
  end

  def handle_cast(:countup_connections, state) do
    {:noreply, %{state| connections: state.connections + 1}}
  end

  def handle_cast(:countdown_connections, state) do
    {:noreply, %{state| connections: state.connections - 1}}
  end

  def handle_cast(:countup_messages, state) do
    {:noreply, %{state| messages: state.messages + 1}}
  end

end
