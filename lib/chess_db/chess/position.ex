defmodule ChessDb.Chess.Position do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Chess.Game

  schema "positions" do
    field :move_index, :integer
    field :fen, :string
    field :zobrist_hash, :integer
    field :move, :string

    belongs_to :game, Game

    timestamps()
  end

  @optional_fields ~w(move)a
  @required_fields ~w(game_id move_index fen zobrist_hash)a

  def changeset(position = %Position{}, attrs) do
    position
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:game)
    |> unique_constraint(:game_and_move_constraint, name: :game_and_move_index)
  end
end
