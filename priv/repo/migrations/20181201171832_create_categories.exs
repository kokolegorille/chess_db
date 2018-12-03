defmodule ChessDb.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :volume, :string
      add :code, :string

      timestamps()
    end

    create unique_index(:categories, [:volume, :code], name: :volume_and_code_index)
  end
end
