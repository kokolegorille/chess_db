defmodule ChessDb.Import do
  @moduledoc """
  Import PGN
  """
  require Logger
  alias ChessDb.Import.Workers.QueueWorker

  def load_pgn(glob) do
    nbr_games = Path.wildcard(glob)
    |> Enum.map(&lazy_load_pgn(&1))
    |> Enum.reduce(0, fn {_, games_length}, acc ->
      acc + games_length
    end)

    {:ok, nbr_games}
  end

  # Create a stream of pgn strings from a (big) file
  defp lazy_load_pgn(file) do
    enqueued = file
    |> File.stream!()
    |> Stream.chunk_by(fn line ->
      line
      |> remove_bom_char()
      |> String.starts_with?("[")
    end)
    |> Stream.chunk_every(2)
    |> Stream.map(&List.flatten/1)
    |> Stream.map(&Enum.join/1)
    |> Stream.filter(fn pgn_string ->
      if String.valid?(pgn_string) do
        true
      else
        Logger.debug fn -> "ARRGGH, string is invalid #{inspect pgn_string}" end
        false
      end
    end)
    |> Enum.map(&enqueue_pgn(&1))

    {:ok, length(enqueued)}
  end

  defp enqueue_pgn(pgn) do
    Logger.debug fn -> "Enqueue #{inspect pgn}" end

    case ChessParser.load_string(pgn) do
      {:ok, trees} ->
        games = trees
        |> Enum.map(&QueueWorker.enqueue/1)
        {:ok, length(games)}
      {:error, _reason} ->
        {:error, 0}
    end
  end

  defp remove_bom_char(string) do
    String.trim(string, "\uFEFF")
  end
end
