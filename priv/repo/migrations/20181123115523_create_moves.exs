defmodule ChessDb.Repo.Migrations.CreateMoves do
  use Ecto.Migration

  def change do
    create table(:moves) do
      add :previous_id, references(:positions, on_delete: :delete_all)
      add :next_id, references(:positions, on_delete: :delete_all)
      add :game_id, references(:games, on_delete: :delete_all)
      add :move_index, :integer, default: 0

      add :san, :string

      timestamps()
    end

    create unique_index(:moves, [:game_id, :move_index], name: :game_and_move_index_index)
  end
end
