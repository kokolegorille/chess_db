defmodule ChessDb.Chess.Game do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Chess.{Player, Position, Move}

  schema "games" do
    field :pgn, :binary
    field :game_info, :map
    field :game_hash, :string
    field :result, :string
    field :year, :integer

    belongs_to :black_player, Player, foreign_key: :black_id
    belongs_to :white_player, Player, foreign_key: :white_id
    has_many :positions, Position
    has_many :moves, Move

    timestamps()
  end

  @optional_fields ~w(black_id white_id result year)a
  @required_fields ~w(game_info pgn)a

  def changeset(%Game{} = game, attrs) do
    game
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:black_player)
    |> assoc_constraint(:white_player)
    |> put_game_hash()
    |> unique_constraint(:game_hash, message: "Game hash already exists")
  end

  # Try to avoid game duplication by hashing game_info
  defp encode_game_info(game_info) do
    list = game_info
    |> Map.to_list
    |> Enum.sort
    |> Enum.map(fn {k, v} -> "#{k}#{v}" end)

    :crypto.hash(:sha256, list) |> Base.encode16
  end

  defp put_game_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{game_info: game_info}} ->
        put_change(changeset, :game_hash, encode_game_info(game_info))
      _ ->
        changeset
    end
  end
end
