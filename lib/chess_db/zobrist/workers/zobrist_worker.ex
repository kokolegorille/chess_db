defmodule ChessDb.Zobrist.Workers.ZobristWorker do
  @moduledoc """
  Zobrist Worker
  """

  use GenServer
  require Logger

  @name __MODULE__
  @external_resource Path.join(:code.priv_dir(:chess_db), "zobrist_hashes.json")

  def start_link(_arg), do: GenServer.start_link(__MODULE__, nil, name: @name)

  def get_zobrist_hash(square, piece), do: get_zobrist_hash({square, piece})
  def get_zobrist_hash(key) do
    case :ets.match(@name, {key, :"$1"}) do
      [] -> nil
      [[result]] -> result
    end
  end

  @impl GenServer
  def init(_) do
    Logger.debug(fn -> "#{inspect(self())}: caching zobrist hashes... OK" end)
    :ets.new(@name, [:named_table])

    # Load data from external resource
    with {:ok, file} <- File.read(@external_resource),
      {:ok, json} <- Jason.decode(file) do

      for {square, map} <- json["pieces"], {piece, hash} <- map do
        :ets.insert(@name, {{String.to_integer(square), piece}, hash})
      end

      for {meta, hash} <- json["meta"] do
        :ets.insert(@name, {meta, hash})
      end
    end

    {:ok, nil}
  end

  @impl GenServer
  def terminate(reason, _state) do
    Logger.debug(fn -> "#{@name} stopped : #{inspect(reason)}" end)
    :ets.delete(@name)
    :ok
  end
end
