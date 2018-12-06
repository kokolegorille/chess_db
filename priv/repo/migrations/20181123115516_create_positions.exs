defmodule ChessDb.Repo.Migrations.CreatePositions do
  use Ecto.Migration

  def change do
    create table(:positions) do
      add :game_id, references(:games, on_delete: :delete_all)
      add :move_index, :integer, default: 0
      #
      add :fen, :string, null: false
      add :zobrist_hash, :bigint, null: false
      add :move, :string

      timestamps()
    end

    create unique_index(:positions, [:game_id, :move_index], name: :game_and_move_index)
    create index(:positions, [:zobrist_hash])
  end
end
