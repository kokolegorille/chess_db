defmodule ChessDb.Repo.Migrations.CreatePositions do
  use Ecto.Migration

  def change do
    create table(:positions) do
      add :game_id, references(:games, on_delete: :delete_all)
      add :move_index, :integer, default: 0
      #
      add :fen, :string
      add :zobrist_hash, :text

      timestamps()
    end

    create unique_index(:positions, [:game_id, :move_index])
  end
end
