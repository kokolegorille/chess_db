defmodule ChessDb.Import.Pipeline.Starter do
  @moduledoc """
  The Producer
  """

  use GenStage
  require Logger

  @queue_polling 5_000

  alias ChessDb.Import.Workers.QueueWorker

  def start_link() do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.debug(fn -> "#{inspect(self())}: Starter started." end)
    {:producer, %{queue: QueueWorker, pending: 0}}
  end

  def handle_info(:try_again, %{queue: queue, pending: demand} = state) do
    send_events_from_queue(queue, demand, state)
  end

  def handle_demand(demand, %{queue: queue, pending: pending} = state) when demand > 0 do
    total_demand = demand + pending
    send_events_from_queue(queue, total_demand, state)
  end

  defp send_events_from_queue(queue, how_many, state) do
    tasks = queue.dequeue(how_many)

    if length(tasks) < how_many do
      Process.send_after(self(), :try_again, @queue_polling)
    end

    {:noreply, tasks, %{state | pending: how_many - length(tasks)}}
  end
end
