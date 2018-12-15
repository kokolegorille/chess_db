defmodule ChessDb.Import.Pipeline.GameStorage do
  @moduledoc """
  The GameStorage Producer Consumer
  """

  use GenStage
  require Logger
  import ChessDb.Common, only: [
    extract_moves: 1,
    play_moves: 1,
    tree_to_pgn: 1,
    extract_game_info: 1
  ]

  alias ChessDb.{Chess, Repo, Zobrist}

  @dummy_state []
  @date_regex ~r/(?<year>\d{4})[\.\/](?<month>\d{2})[\.\/](?<day>\d{2})/
  def start_link([name, subscription_options]) do
    GenStage.start_link(__MODULE__, subscription_options, name: name)
  end

  def init(subscription_options) do
    Logger.debug(fn -> "#{inspect(self())}: GameStorage started." end)
    {:producer_consumer, @dummy_state, subscription_options}
  end

  def handle_events(tasks, _from, _state) do
    stored = Enum.map(tasks, &store_game(&1))
    {:noreply, stored, @dummy_state}
  end

  # PRIVATE

  defp store_game({:tree, tags, elems} = tree) do
    Logger.debug(fn -> "Store game #{inspect tree}" end)

    game_info = extract_game_info(tags)

    game_params = %{
      white_id: maybe_player_id_by_name(game_info["White"]),
      black_id: maybe_player_id_by_name(game_info["Black"]),
      game_info: game_info,
      pgn: tree_to_pgn(tree),
      event: game_info["Event"],
      site: game_info["Site"],
      round: game_info["Round"],
      year: maybe_year(game_info["Date"]),
      month: maybe_month(game_info["Date"]),
      day: maybe_day(game_info["Date"]),
      result: maybe_result(elems),
      white_elo: game_info["WhiteElo"],
      black_elo: game_info["BlackElo"]
    }

    case persist_game(game_params) do
      {:ok, game} ->
        case process_positions_and_moves(game, elems) do
          :ok -> game
          :error -> :error
        end
      {:error, changeset} ->
        # Mostly because the game is a duplicate!
        Logger.debug(fn -> "skipping game #{inspect changeset.errors}" end)
        :error
    end
  end

  defp persist_game(game_params) do
    Logger.debug(fn -> "Persisting game..." end)
    Chess.create_game(game_params)
  end

  defp process_positions_and_moves(game, elems) do
    moves = extract_moves(elems)
    positions = play_moves(moves)

    if length(moves) == length(positions) - 1 do
      # {_number, inserted} = persist_positions(game.id, positions)
      # persist_moves(game.id, moves, inserted)
      persist_positions(game.id, positions, moves)
      :ok
    else
      # This happens when the numbers of moves and positions are not in sync
      Logger.debug(fn ->
        "OOOPS wrong move numbers #{length(moves)} - #{length(positions) - 1} for game : #{inspect game.game_info}"
      end)
      :error
    end
  end

  defp persist_positions(game_id, positions, moves) do
    Logger.debug(fn -> "Persisting positions..." end)

    entries = positions
    |> Enum.with_index()
    |> Enum.map(fn {position, index} ->
      now =
        NaiveDateTime.utc_now
        |> NaiveDateTime.truncate(:second)

      fen = Chessfold.position_to_string(position)

      pos = %{
        game_id: game_id,
        move_index: index,
        fen: fen,
        inserted_at: now,
        updated_at: now,
        zobrist_hash: Zobrist.fen_to_zobrist_hash(fen)
      }
      move = Enum.at(moves, index)
      if move, do: Map.put(pos, :move, move), else: pos
    end)

    # Repo.insert_all(Chess.Position, entries, returning: [:id])
    Repo.insert_all(Chess.Position, entries)
  end

  defp maybe_player_id_by_name(name) when is_nil(name), do: nil
  defp maybe_player_id_by_name(name) do
    last_and_first = name
    |> String.split(",")

    last = Enum.at(last_and_first, 0)
    first = Enum.at(last_and_first, 1)
    first = case first do
      nil -> nil
      first -> String.trim_leading(first, " ")
    end

    user = if is_nil(first) do
      Chess.first_or_create_player %{full_name: name, last_name: last}
    else
      Chess.first_or_create_player %{full_name: name, last_name: last, first_name: first}
    end
    user.id
  end

  defp maybe_year(date_string) when is_binary(date_string) do
    case Regex.named_captures(@date_regex, date_string) do
      %{"year" => year} -> String.to_integer(year)
      _ -> nil
    end
  end
  defp maybe_year(_date_string), do: nil

  defp maybe_month(date_string) when is_binary(date_string) do
    case Regex.named_captures(@date_regex, date_string) do
      %{"month" => month} -> String.to_integer(month)
      _ -> nil
    end
  end
  defp maybe_month(_date_string), do: nil

  defp maybe_day(date_string) when is_binary(date_string) do
    case Regex.named_captures(@date_regex, date_string) do
      %{"day" => day} -> String.to_integer(day)
      _ -> nil
    end
  end
  defp maybe_day(_date_string), do: nil

  defp maybe_result(elems) do
    elem =
      elems
      |> Enum.filter(fn e ->
        case e do
          {:result, _, _} -> true
          _ -> false
        end
      end)
      |> List.first

    case elem do
      {:result, _, result} -> to_string(result)
      _ -> nil
    end
  end
end
