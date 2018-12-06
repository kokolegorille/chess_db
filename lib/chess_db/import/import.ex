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
    |> File.stream!([:trim_bom])
    |> Stream.chunk_by( &String.starts_with?(&1, "["))
    |> Stream.chunk_every(2)
    |> Stream.map(&List.flatten/1)
    |> Stream.map(&Enum.join/1)
    |> Stream.map(& force_utf8(&1))
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

  # https://elixirforum.com/t/how-to-replace-accented-letters-with-ascii-letters/539/4
  defp force_utf8(string) do
    if String.valid?(string) do
      string
    else
      new_string = :iconv.convert "utf-8", "ascii//translit", string
      Logger.debug fn -> "Converting #{inspect string} to #{new_string}" end
      new_string
    end
  end
end
