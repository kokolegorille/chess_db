defmodule ChessDb.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :last_name, :citext, null: false
      add :first_name, :citext

      timestamps()
    end

    create unique_index(:players, [:last_name, :first_name], name: :last_and_first_index)
    create index(:players, [:last_name])
  end
end
