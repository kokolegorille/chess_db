defmodule ChessDb.Chess.Player do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Chess.Game

  schema "players" do
    field :name, :string
    has_many :black_games, Game, foreign_key: :black_id
    has_many :white_games, Game, foreign_key: :white_id

    timestamps()
  end

  @required_fields ~w(name)a

  def changeset(player = %Player{}, attrs) do
    player
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:name)
  end
end
