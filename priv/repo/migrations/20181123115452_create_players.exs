defmodule ChessDb.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :citext, null: false

      timestamps()
    end

    create unique_index(:players, [:name])
  end
end
