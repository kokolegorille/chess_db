defmodule ChessDb.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :full_name, :citext, null: false
      add :last_name, :citext, null: false
      add :first_name, :citext

      timestamps()
    end

    create unique_index(:players, :full_name)
    create index(:players, [:last_name])
  end
end
