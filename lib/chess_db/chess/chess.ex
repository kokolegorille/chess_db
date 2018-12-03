defmodule ChessDb.Chess do
  @moduledoc """
  The Chess context
  """
  import Ecto.Query, warn: false

  alias ChessDb.Repo
  alias ChessDb.Chess.{Player, Game, Position, Move}

  # =================================================================
  # PLAYERS
  # =================================================================

  def list_players do
    Repo.all(Player)
  end

  def get_player(id) do
    Repo.get(Player, id)
  end

  def get_player!(id) do
    Repo.get!(Player, id)
  end

  def get_player_by(params) do
    Repo.get_by(Player, params)
  end

  def get_player_by!(params) do
    Repo.get_by!(Player, params)
  end

  def create_player(attrs \\ %{}) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  def first_or_create_player(attrs \\ %{}) do
    case create_player(attrs) do
      {:ok, player} -> player
      {:error, _changeset} -> get_player_by(attrs)
    end

    # # THIS CAN BE A RACE CONDITION!
    # case get_player_by(attrs) do
    #   nil ->
    #     {:ok, player} = create_player(attrs)
    #     player
    #   player -> player
    # end
  end

  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  def delete_player(%Player{} = player), do: Repo.delete(player)

  def change_player(%Player{} = player) do
    Player.changeset(player, %{})
  end

  # =================================================================
  # GAMES
  # =================================================================

  def list_games do
    Repo.all(Game)
  end

  def list_player_games(%Player{} = player) do
    Game
    |> player_games_query(player)
    |> Repo.all
  end

  def get_game(id) do
    Repo.get(Game, id)
  end

  def get_game!(id) do
    Repo.get!(Game, id)
  end

  def get_game_by(params) do
    Repo.get_by(Game, params)
  end

  def get_game_by!(params) do
    Repo.get_by!(Game, params)
  end

  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  def delete_game(%Game{} = game), do: Repo.delete(game)

  def change_game(%Game{} = game) do
    Game.changeset(game, %{})
  end

  # =================================================================
  # POSITIONS
  # =================================================================

  def list_positions do
    Repo.all(Position)
  end

  def list_positions_by_zobrist_hash(zobrist_hash) do
    from(p in Position, where: p.zobrist_hash == ^zobrist_hash)
    |> Repo.all
  end

  def list_game_positions(%Game{} = game) do
    Position
    |> game_positions_query(game)
    |> Repo.all
  end

  def get_position(id) do
    Repo.get(Position, id)
  end

  def get_position!(id) do
    Repo.get!(Position, id)
  end

  def create_position(attrs \\ %{}) do
    %Position{}
    |> Position.changeset(attrs)
    |> Repo.insert()
  end

  def update_position(%Position{} = position, attrs) do
    position
    |> Position.changeset(attrs)
    |> Repo.update()
  end

  def delete_position(%Position{} = position), do: Repo.delete(position)

  def change_position(%Position{} = position) do
    Position.changeset(position, %{})
  end

  # =================================================================
  # MOVES
  # =================================================================

  def list_moves do
    Repo.all(Move)
  end

  def get_move(id) do
    Repo.get(Move, id)
  end

  def get_move!(id) do
    Repo.get!(Move, id)
  end

  def create_move(attrs \\ %{}) do
    %Move{}
    |> Move.changeset(attrs)
    |> Repo.insert()
  end

  def update_move(%Move{} = move, attrs) do
    move
    |> Move.changeset(attrs)
    |> Repo.update()
  end

  def delete_move(%Move{} = move), do: Repo.delete(move)

  def change_move(%Move{} = move) do
    Move.changeset(move, %{})
  end

  # =================================================================
  # PRIVATE
  # =================================================================

  defp player_games_query(query, %Player{id: player_id}) do
    from(g in query, where: g.white_id == ^player_id or g.black_id == ^player_id)
  end

  defp game_positions_query(query, %Game{id: game_id}) do
    from(p in query, where: p.game_id == ^game_id)
  end
end
