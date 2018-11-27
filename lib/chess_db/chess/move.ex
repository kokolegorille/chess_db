defmodule ChessDb.Chess.Move do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Chess.{Game, Position}

  schema "moves" do
    field :move_index, :integer
    field :san, :string

    belongs_to :game, Game
    belongs_to :previous_position, Position, foreign_key: :previous_id
    belongs_to :next_position, Position, foreign_key: :next_id

    timestamps()
  end

  @required_fields ~w(game_id move_index san previous_id next_id)a

  def changeset(move = %Move{}, attrs) do
    move
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:previous_position)
    |> assoc_constraint(:next_position)
    |> assoc_constraint(:game)
  end
end
