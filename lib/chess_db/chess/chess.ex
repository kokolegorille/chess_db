defmodule ChessDb.Chess do
  @moduledoc """
  The Chess context
  """
  import Ecto.Query, warn: false
  import ChessDb.Common, only: [sanitize_zobrist: 1]

  require Logger

  alias ChessDb.Repo
  alias ChessDb.Chess.{Player, Game, Position}

  # Relay connection from query needs access to repo
  def process_repo(query), do: query |> Repo.all

  # =================================================================
  # PLAYERS
  # =================================================================

  def list_players(args \\ []), do: args |> list_players_query() |> Repo.all()

  def list_players_query(args) do
    args
    |> Enum.reduce(Player, fn
      {:order, order}, query ->
        query |> order_by([{^order, :last_name}, {^order, :first_name}])
      {:name, name}, query ->
        from q in query, where: ilike(q.last_name, ^"%#{name}%") or ilike(q.first_name, ^"%#{name}%")
      arg, query ->
        Logger.debug(fn -> "args is not matched in query #{inspect arg}" end)
        query
    end)
  end

  def list_player_games_query(%Player{id: player_id}, args) do
    from(
      g in list_games_query(args),
      where: g.white_id == ^player_id or g.black_id == ^player_id
    )
  end

  def list_player_games(%Player{} = player, args \\ []) do
    player
    |> list_player_games_query(args)
    |> Repo.all
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

  def list_games_query(args) do
    args
    |> Enum.reduce(Game, fn
      {:order, order}, query ->
        order_by(query, [{^order, :year}, :event, :round])
      {:filter, filter}, query ->
        filter_game_with(query, filter)
      arg, query ->
        Logger.info("args is not matched in query #{inspect arg}")
        query
    end)
  end

  defp filter_game_with(query, filter) do
    filter
    |> Enum.reduce(query, fn
      {:event, event}, query ->
        from q in query, where: ilike(q.event, ^"%#{event}%")
      {:site, site}, query ->
        from q in query, where: ilike(q.site, ^"%#{site}%")
      {:round, round}, query ->
        from q in query, where: ilike(q.round, ^"%#{round}%")
      {:result, result}, query ->
        from q in query, where: q.result == ^result
      {:year, year}, query ->
        from q in query, where: q.year == ^year
      {:white_player, name}, query ->
        from q in query,
          join: p in Player,
          on: [id: q.white_id],
          where: ilike(p.last_name, ^"%#{name}%") or ilike(p.first_name, ^"%#{name}%")
      {:black_player, name}, query ->
        from q in query,
          join: p in Player,
          on: [id: q.black_id],
          where: ilike(p.last_name, ^"%#{name}%") or ilike(p.first_name, ^"%#{name}%")
      {:zobrist_hash, zobrist_hash}, query ->
        from q in query,
          join: p in Position,
          on: [game_id: q.id],
          where: p.zobrist_hash == ^sanitize_zobrist(zobrist_hash),
          distinct: true
    end)
  end

  def list_games(args \\ []) do
    list_games_query(args)
    |> Repo.all()
    |> Repo.preload([:white_player, :black_player])
  end

  def list_game_positions_query(%Game{id: game_id}, args) do
    from(
      p in list_positions_query(args),
      where: p.game_id == ^game_id
    )
  end

  def list_game_positions(%Game{} = game, args \\ []) do
    game
    |> list_game_positions_query(args)
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

  def list_positions_query(args) do
    args
    |> Enum.reduce(Position, fn
      {:filter, filter}, query ->
        filter_position_with(query, filter)
      arg, query ->
        Logger.info("args is not matched in query #{inspect arg}")
        query
    end)
    |> order_by([:game_id, :move_index])
  end

  defp filter_position_with(query, filter) do
    filter
    |> Enum.reduce(query, fn
      {:zobrist_hash, zobrist_hash}, query ->
        from q in query, where: q.zobrist_hash == ^zobrist_hash
      {:move, move}, query ->
        from q in query, where: q.move == ^move
      {:fen, fen}, query ->
        from q in query, where: q.fen == ^fen
    end)
  end

  def list_positions(args \\ []) do
    args
    |> list_positions_query()
    |> Repo.all()
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
end
