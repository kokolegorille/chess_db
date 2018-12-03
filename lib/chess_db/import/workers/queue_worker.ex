defmodule ChessDb.Import.Workers.QueueWorker do
  @moduledoc """
  The QueueWorker GenServer
  """

  use GenServer
  require Logger

  # ======================================================
  # USE ETS & QUEUE
  # ======================================================

  @name __MODULE__
  @key "queue_key"

  def start_link(_arg), do: GenServer.start_link(__MODULE__, nil, name: @name)

  def dequeue(no_items \\ 1) do
    [{_, queue} | _] = :ets.lookup @name, @key

    # Beware because :queue.split does not act like Enum.split!
    # It generates an error if splitting number is bigger than queue length
    case :queue.len(queue) do
      0 ->
        :queue.to_list(queue)
      x when x <= no_items ->
        :ets.insert(@name, {@key, :queue.new})
        :queue.to_list(queue)
      x when x > no_items ->
        {events, new_queue} = :queue.split(no_items, queue)
        :ets.insert(@name, {@key, new_queue})
        :queue.to_list(events)
    end
  end

  def enqueue(event) do
    [{_, queue} | _] = :ets.lookup @name, @key
    new_queue = :queue.in event, queue
    :ets.insert(@name, {@key, new_queue})
    :ok
  end

  @impl GenServer
  def init(_) do
    Logger.debug(fn -> "#{inspect(self())}: Queue worker started." end)

    :ets.new(@name, [:named_table, :public, write_concurrency: true])
    :ets.insert(@name, {@key, :queue.new})
    {:ok, nil}
  end

  @impl GenServer
  def terminate(reason, _state) do
    Logger.debug(fn -> "#{@name} stopped : #{inspect(reason)}" end)
    :ets.delete(@name)
    :ok
  end

  # @timeout 20_000

  # # ======================================================
  # # USE ERLANG QUEUE => BOTTLENECK!
  # # ======================================================

  # def start_link(_args) do
  #   GenServer.start_link(__MODULE__, :queue.new, name: __MODULE__)
  # end

  # def dequeue(no_items \\ 1) do
  #   GenServer.call(__MODULE__, {:dequeue, no_items}, @timeout)
  # end

  # def enqueue(event) do
  #   GenServer.cast(__MODULE__, {:enqueue, event})
  # end

  # def init(queue) do
  #   Logger.debug(fn -> "#{inspect(self())}: QueueWorker started." end)

  #   {:ok, queue}
  # end

  # def handle_call({:dequeue, no_items}, _from, queue) do
  #   if :queue.is_empty(queue) do
  #     {:reply, :queue.to_list(queue), queue}
  #   else
  #     {events, new_queue} = :queue.split(no_items, queue)
  #     {:reply, :queue.to_list(events), new_queue}
  #   end
  # end

  # def handle_cast({:enqueue, event}, queue) do
  #   new_queue = :queue.in event, queue
  #   {:noreply, new_queue}
  # end

  # # ======================================================
  # # The process approach => BOTTLENECK!
  # # ======================================================

  # def start_link(_args) do
  #   GenServer.start_link(__MODULE__, [], name: __MODULE__)
  # end

  # def dequeue(no_items \\ 1) do
  #   GenServer.call(__MODULE__, {:dequeue, no_items})
  # end

  # def enqueue(event) do
  #   GenServer.cast(__MODULE__, {:enqueue, event})
  # end

  # def init(queue) do
  #   Logger.debug(fn -> "#{inspect(self())}: QueueWorker started." end)

  #   {:ok, queue}
  # end

  # def handle_call({:dequeue, _no_items}, _from, [] = queue) do
  #   {:reply, queue, queue}
  # end
  # def handle_call({:dequeue, no_items}, _from, queue) do
  #   {events, queue} = Enum.split(queue, no_items)
  #   {:reply, events, queue}
  # end

  # def handle_cast({:enqueue, event}, queue) do
  #   {:noreply, queue ++ [event]}
  # end
end
