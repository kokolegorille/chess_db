defmodule ChessDb.Chess.Game do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Chess.{Player, Position}

  schema "games" do
    field :sgf, :binary
    field :game_info, :map
    field :result, ChessDb.Result
    field :year, :integer

    belongs_to :black_player, Player, foreign_key: :black_id
    belongs_to :white_player, Player, foreign_key: :white_id
    has_many :positions, Position

    timestamps()
  end

  @optional_fields ~w(result year)a
  @required_fields ~w(black_id white_id game_info sgf)a

  def changeset(%Game{} = game, attrs) do
    game
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:black_player)
    |> assoc_constraint(:white_player)
  end
end
