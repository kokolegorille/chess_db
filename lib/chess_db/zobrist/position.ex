defmodule ChessDb.Zobrist.Position do
  defstruct [
    board: nil,
    turn: nil,
    castling: nil,
    en_passant_square: nil
  ]
end
