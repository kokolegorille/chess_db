defmodule ChessDb.Eco.Category do
  @moduledoc """
  The Category Schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias ChessDb.Eco.SubCategory

  schema "categories" do
    field :volume, :string
    field :code, :string

    has_many :sub_categories, SubCategory

    timestamps()
  end

  @required_fields ~w(volume code)a

  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:volume_and_code_constraint, name: :volume_and_code_index)
  end
end
