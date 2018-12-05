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
      result: maybe_result(elems)
    }

    case persist_game(game_params) do
      {:ok, game} ->
        process_positions_and_moves(game, elems)
        game
      {:error, changeset} ->
        # Mostly because the game is a duplicate!
        Logger.debug(fn -> "skipping game #{inspect changeset.errors}" end)
        :error
    end
  end

  defp process_positions_and_moves(game, elems) do
    moves = extract_moves(elems)
    positions = play_moves(moves)

    if length(moves) == length(positions) - 1 do
      {_number, inserted} = persist_positions(game.id, positions)
      persist_moves(game.id, moves, inserted)
      :ok
    else
      # This happens when the moves cannot be linked
      # to their respective previous and next position
      Logger.debug(fn ->
        "OOOPS wrong move numbers for game : #{inspect game.game_info}"
      end)
    end
  end

  defp persist_game(game_params) do
    Logger.debug(fn -> "Persisting game..." end)
    Chess.create_game(game_params)
  end

  defp persist_positions(game_id, positions) do
    Logger.debug(fn -> "Persisting positions..." end)

    entries = positions
      |> Enum.with_index()
      |> Enum.map(fn {position, index} ->
        now =
          NaiveDateTime.utc_now
          |> NaiveDateTime.truncate(:second)

        fen = Chessfold.position_to_string(position)

        %{
          game_id: game_id,
          move_index: index,
          fen: fen,
          inserted_at: now,
          updated_at: now,
          zobrist_hash: Zobrist.fen_to_zobrist_hash(fen)
        }
      end)

      Repo.insert_all(Chess.Position, entries, returning: [:id])
  end

  defp persist_moves(game_id, moves, inserted) do
    Logger.debug(fn -> "Persisting moves..." end)

    entries = moves
    |> Enum.with_index()
    |> Enum.map(fn {move, index} ->
      now =
        NaiveDateTime.utc_now
        |> NaiveDateTime.truncate(:second)

      # Set associations
      %Chess.Position{id: previous_id} = Enum.at(inserted, index)
      %Chess.Position{id: next_id} = Enum.at(inserted, index + 1)

      %{
        game_id: game_id,
        previous_id: previous_id,
        next_id: next_id,
        move_index: index,
        san: move,
        inserted_at: now,
        updated_at: now,
      }
    end)

    Repo.insert_all(Chess.Move, entries)
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
    case Regex.named_captures(~r/(?<date>\d{4})/, date_string) do
      %{"date" => date} -> String.to_integer(date)
      _ -> nil
    end
  end
  defp maybe_year(_date_string), do: nil

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
