defmodule ChessDb.Chess.Position do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Chess.{Game, Move}

  schema "positions" do
    field :move_number, :integer
    field :pieces, {:array, :string}
    field :turn, ChessDb.TurnEnum
    field :allowed_castling, :string
    field :en_passant_square, :string
    field :half_move_clock, :integer
    field :fen, :string
    field :zobrist_hash, :binary

    belongs_to :game, Game
    has_one :previous_move, Move, foreign_key: :previous_id
    has_one :next_move, Move, foreign_key: :next_id

    has_one :previous_position, through: [:previous_move, :previous_position]
    has_one :next_position, through: [:next_move, :next_position]

    timestamps()
  end

  @optional_fields ~w(allowed_castling en_passant_square zobrist_hash)a
  @required_fields ~w(game_id move_number pieces turn half_move_clock fen)a

  def changeset(position = %Position{}, attrs) do
    position
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:game)
  end
end
