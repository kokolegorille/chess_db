defmodule ChessDb.Eco.SubCategory do
  @moduledoc """
  The SubCategory Schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Eco.Category

  schema "sub_categories" do
    field :position, :integer
    field :code, :string
    field :description, :string
    field :pgn, :string
    field :zobrist_hash, :integer

    belongs_to :category, Category

    timestamps()
  end

  @required_fields ~w(category_id position code description pgn zobrist_hash)a

  def changeset(%SubCategory{} = sub_category, attrs) do
    sub_category
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:category)
    |> unique_constraint(:category_and_position_constraint, name: :category_and_position_index)
  end
end

