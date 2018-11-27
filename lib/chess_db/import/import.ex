defmodule ChessDb.Import do
  @moduledoc """
  Import PGN
  """

  alias ChessDb.Import.Workers.QueueWorker

  # def load_pgn(file) when is_binary(file) do
  #   case ChessParser.load_file(file) do
  #     {:ok, trees} ->
  #       games = trees
  #       |> Enum.map(&QueueWorker.enqueue/1)
  #       {:ok, length(games)}
  #     {:error, reason} ->
  #       {:error, reason}
  #   end
  # end

  def load_pgn(glob) do
    nbr_games = Path.wildcard(glob)
    |> Enum.map(&extract_trees(&1))
    |> Enum.filter(fn {atom, _} -> atom == :ok end)
    |> Enum.reduce(0, fn {:ok, games_length}, acc ->
      acc + games_length
    end)

    {:ok, nbr_games}
  end

  defp extract_trees(file) do
    try do
      case ChessParser.load_file(file) do
        {:ok, trees} ->
          games = trees
          |> Enum.map(&QueueWorker.enqueue/1)
          {:ok, length(games)}
        {:error, _reason} ->
          {:error, 0}
      end
    rescue
      RuntimeError -> "Error!"
    end
  end
end
