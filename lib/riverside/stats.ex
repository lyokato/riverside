defmodule Riverside.Stats do
  use GenServer

  defstruct current_connections: 0,
            total_connections: 0,
            incoming_messages: 0,
            outgoing_messages: 0,
            started_at: 0

  def current_state do
    GenServer.call(__MODULE__, :current_state)
  end

  def number_of_current_connections do
    GenServer.call(__MODULE__, :number_of_current_connections)
  end

  def number_of_total_connections do
    GenServer.call(__MODULE__, :number_of_total_connections)
  end

  def number_of_messages do
    GenServer.call(__MODULE__, :number_of_messages)
  end

  def countup_incoming_messages do
    GenServer.cast(__MODULE__, :countup_incoming_messages)
  end

  def countup_outgoing_messages do
    GenServer.cast(__MODULE__, :countup_outgoing_messages)
  end

  def countup_connections do
    GenServer.cast(__MODULE__, :countup_connections)
  end

  def countdown_connections do
    GenServer.cast(__MODULE__, :countdown_connections)
  end

  def start_link(_opts), do: start_link()

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  defp new() do
    %__MODULE__{
      current_connections: 0,
      total_connections: 0,
      incoming_messages: 0,
      outgoing_messages: 0,
      started_at: Riverside.IO.Timestamp.seconds()
    }
  end

  def init(_args) do
    {:ok, new()}
  end

  def handle_call(:number_of_current_connections, _from, state) do
    {:reply, state.current_connections, state}
  end

  def handle_call(:current_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:number_of_messages, _from, state) do
    {:reply, state.messages, state}
  end

  def handle_cast(
        :countup_connections,
        %{total_connections: total, current_connections: current} = state
      ) do
    {:noreply, %{state | current_connections: current + 1, total_connections: total + 1}}
  end

  def handle_cast(:countdown_connections, state) do
    {:noreply, %{state | current_connections: state.current_connections - 1}}
  end

  def handle_cast(:countup_incoming_messages, state) do
    {:noreply, %{state | incoming_messages: state.incoming_messages + 1}}
  end

  def handle_cast(:countup_outgoing_messages, state) do
    {:noreply, %{state | outgoing_messages: state.outgoing_messages + 1}}
  end
end
