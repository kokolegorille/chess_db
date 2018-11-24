defmodule ChessDb.Repo.Migrations.CreateMoves do
  use Ecto.Migration

  def change do
    create table(:moves) do
      add :previous_id, references(:positions, on_delete: :delete_all)
      add :next_id, references(:positions, on_delete: :delete_all)

      add :from, :string
      add :to, :string
      add :castling, :boolean, default: false
      add :taken, :boolean, default: false

      timestamps()
    end
  end
end
