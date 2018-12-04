defmodule ChessDb.Chess.Player do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Chess.Game

  schema "players" do
    field :full_name, :string
    field :last_name, :string
    field :first_name, :string
    has_many :black_games, Game, foreign_key: :black_id
    has_many :white_games, Game, foreign_key: :white_id

    timestamps()
  end

  @optional_fields ~w(first_name)a
  @required_fields ~w(full_name last_name)a

  def changeset(%Player{} = player, attrs) do
    player
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:full_name)
  end
end
