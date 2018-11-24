defmodule ChessDb.Chess.Move do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Chess.Position

  schema "moves" do
    field :from, :string
    field :to, :string
    field :castling, :boolean
    field :taken, :boolean

    belongs_to :previous_position, Position, foreign_key: :previous_id
    belongs_to :next_position, Position, foreign_key: :next_id

    timestamps()
  end

  @optional_fields ~w(castling taken)a
  @required_fields ~w(from to previous_id next_id)a

  def changeset(move = %Move{}, attrs) do
    move
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:previous_position)
    |> assoc_constraint(:next_position)
  end
end
