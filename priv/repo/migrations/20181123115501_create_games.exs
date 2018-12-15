defmodule ChessDb.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :white_id, references(:players, on_delete: :nilify_all)
      add :black_id, references(:players, on_delete: :nilify_all)
      add :game_hash, :string

      add :pgn, :text
      add :game_info, :map
      add :event, :string
      add :site, :string
      add :round, :string
      add :result, :string
      add :year, :integer
      add :month, :integer
      add :day, :integer

      add :white_elo, :integer
      add :black_elo, :integer

      timestamps()
    end

    create unique_index(:games, [:game_hash])
    create index(:games, [:year, :month, :day])
  end
end
