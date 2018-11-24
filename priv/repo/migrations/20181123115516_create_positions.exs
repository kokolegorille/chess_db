defmodule ChessDb.Repo.Migrations.CreatePositions do
  use Ecto.Migration

  def change do
    create table(:positions) do
      add :game_id, references(:games, on_delete: :delete_all)
      #
      add :move_number, :integer, default: 0
      #
      add :pieces, {:array, :map}
      add :turn, :string
      add :allowed_castling, :string
      add :en_passant_square, :string
      add :half_move_clock, :integer, default: 0
      #
      add :fen, :string
      add :zobrist_hash, :text

      timestamps()
    end

    create unique_index(:positions, [:game_id, :move_number])
  end
end
