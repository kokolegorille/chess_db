defmodule ChessDb.Import.Workers.QueueWorker do
  @moduledoc """
  The QueueWorker GenServer
  """

  use GenServer
  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def dequeue(no_items \\ 1) do
    GenServer.call(__MODULE__, {:dequeue, no_items})
  end

  def enqueue(event) do
    GenServer.cast(__MODULE__, {:enqueue, event})
  end

  def init(queue) do
    Logger.debug(fn -> "#{inspect(self())}: QueueWorker started." end)

    {:ok, queue}
  end

  def handle_call({:dequeue, _no_items}, _from, [] = queue) do
    {:reply, queue, queue}
  end
  def handle_call({:dequeue, no_items}, _from, queue) do
    {events, queue} = Enum.split(queue, no_items)
    {:reply, events, queue}
  end

  def handle_cast({:enqueue, event}, queue) do
    {:noreply, queue ++ [event]}
  end
end
