defmodule ChessDb.Common do
  @moduledoc """
  Common tools
  """

  require Logger

  def extract_moves(elems) do
    elems
    |> Enum.filter(fn e ->
      case e do
        {:san, _, _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {:san, _, charlist_move} ->
      charlist_move |> to_string() |> remove_move_marks()
    end)
  end

  def play_moves(moves, position \\ initial_position()) do
    moves
    |> Enum.reduce_while([position], fn move, acc ->
      last_position = List.first(acc)
      case Chessfold.play(last_position, move) do
        {:ok, new_position} ->
          {:cont, [new_position | acc]}
        {:error, _reason} ->
          Logger.debug fn -> "#{inspect last_position} for #{move}" end
          {:halt, acc}
      end
    end)
    |> Enum.reverse
  end

  def initial_position do
    string = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    Chessfold.string_to_position string
  end

  def tree_to_pgn({:tree, tags, elems}) do
    header = tags |> Enum.map_join("\n", fn {:tag, _, tag} -> to_string(tag) end)
    body = elems |> Enum.map_join(" ", fn {_, _, elem} -> to_string(elem) end)

    header <> "\n" <> body
  end

  def extract_game_info(tags) do
    tags
    |> Enum.reduce(%{}, fn {:tag, _, key_val}, acc ->
      %{"key" => key, "value" => value} = sanitize(key_val)
      Map.put(acc, key, value)
    end)
  end

  # Private

  defp sanitize(key_val) do
    key_val
    |> to_string
    |> String.trim_leading("[")
    |> String.trim_trailing("]")
    |> extract_key_val()
  end

  defp extract_key_val(string) do
    Regex.named_captures(~r/(?<key>.*)\s\"(?<value>.*)\"/, string)
  end

  # Remove all marks for check, mate, etc. at the end of a move
  # Beware not to remove - in O-O!
  defp remove_move_marks(move), do: String.replace(move, ~r/[\#+-]*$/, "")
end
