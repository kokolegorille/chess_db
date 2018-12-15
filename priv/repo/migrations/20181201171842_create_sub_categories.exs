defmodule ChessDb.Repo.Migrations.CreateSubCategories do
  use Ecto.Migration

  def change do
    create table(:sub_categories) do
      add :category_id, references(:categories, on_delete: :delete_all)
      add :position, :integer
      add :code, :string
      add :description, :string
      add :pgn, :string
      add :fen, :string
      add :zobrist_hash, :bigint, null: false

      timestamps()
    end

    create unique_index(:sub_categories, [:category_id, :position], name: :category_and_position_index)
    create index(:sub_categories, [:position])
    create index(:sub_categories, [:zobrist_hash])
  end
end
