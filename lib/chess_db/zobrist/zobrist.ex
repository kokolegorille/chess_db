defmodule ChessDb.Zobrist do
  @moduledoc """
  Zobrist Hashing
  """
  use Bitwise

  @max_int 9_223_372_036_854_775_807
  @pieces [
    "p", "n", "b", "r", "q", "k",
    "P", "N", "B", "R", "Q", "K"
  ]

  @meta [
    "turn",
    "castling_K",
    "castling_Q",
    "castling_k",
    "castling_q",
    "en_passant_a",
    "en_passant_b",
    "en_passant_c",
    "en_passant_d",
    "en_passant_e",
    "en_passant_f",
    "en_passant_g",
    "en_passant_h",
  ]

  @json_file "./priv/zobrist_hashes.json"

  alias ChessDb.Zobrist.Workers.ZobristWorker
  alias ChessDb.Zobrist.Position

  defdelegate get_zobrist_hash(square, piece), to: ZobristWorker
  defdelegate get_zobrist_hash(key), to: ZobristWorker

  # inc_zobrist_hash(previous_hash, position_diff)

  def generate_hashes do
    pieces = for square <- 1..64, piece <- @pieces do
      {to_string(square), %{piece => generate_hash()}}
    end
    |> Enum.reduce(%{}, fn {square, map}, acc ->
      previous_map = Map.get(acc, square, %{})
      Map.put(acc, square, Map.merge(map, previous_map))
    end)

    meta = for m <- @meta do
      {m, generate_hash()}
    end
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)

    %{
      pieces: pieces,
      meta: meta
    }
  end

  def fen_to_zobrist_hash(fen) when is_binary(fen) do
    fen
    |> fen_to_position()
    |> full_zobrist_hash()
  end

  def fen_to_position(fen) when is_binary(fen) do

    [position_string, turn, castling, en_passant_square|_rest] = String.split(fen, " ")
    board = position_string
    |> String.split("/")
    |> Enum.map(fn row ->

      row
      |> String.graphemes()
      |> Enum.map(fn char ->
        cond do
          String.match?(char, ~r/\d/) == true ->
            char
            |> String.to_integer()
            |> create_empty()
          String.match?(char, ~r/[a-zA-Z]/) == true ->
            [char]
        end
      end)
      |> List.flatten()
    end)

    %Position{
      board: board,
      turn: turn,
      castling: castling,
      en_passant_square: en_passant_square
    }
  end

  def generate_json_hashes do
    {:ok, json} = generate_hashes()
    |> Jason.encode
    json
  end

  # To generate a new table...
  # But be careful as it will overwrite previous file!
  def create_new_table() do
    File.write(@json_file, ChessDb.Zobrist.generate_json_hashes)
  end

  def full_zobrist_hash(%Position{board: board, turn: turn, castling: castling, en_passant_square: en_passant_square} = _position) do
    hashes = for {row, row_idx} <- Enum.with_index(board), {piece, piece_idx} <- Enum.with_index(row) do
      # IO.puts "row: #{inspect row} row_idx: #{row_idx} piece: #{inspect piece} piece_idx: #{piece_idx}"

      piece = case piece do
        "-" -> :empty
        piece -> piece
      end
      square = row_idx * 8 + piece_idx + 1

      get_zobrist_hash(square, piece)
    end

    hashes = if turn == "b" do
      [get_zobrist_hash("turn") | hashes]
    else
      hashes
    end

    hashes = if String.contains?(castling, "K") do
      [get_zobrist_hash("castling_K") | hashes]
    else
      hashes
    end

    hashes = if String.contains?(castling, "Q") do
      [get_zobrist_hash("castling_Q") | hashes]
    else
      hashes
    end

    hashes = if String.contains?(castling, "k") do
      [get_zobrist_hash("castling_k") | hashes]
    else
      hashes
    end

    hashes = if String.contains?(castling, "q") do
      [get_zobrist_hash("castling_q") | hashes]
    else
      hashes
    end

    hashes = case en_passant_square do
      "-" ->
        hashes
      en_passant_square ->
        col = en_passant_square |> String.split |> List.first
        [get_zobrist_hash("en_passant_#{col}") | hashes]
    end

    hashes
    |> Enum.reject(&is_nil(&1))
    |> Enum.reduce(0, fn hash, acc ->
      acc ^^^ hash
    end)
  end

  # position -> hash

  # Private

  defp generate_hash, do: :rand.uniform @max_int

  defp create_empty(number) when is_integer(number) do
    "-"
    |> String.duplicate(number)
    |> String.graphemes()
  end
end
