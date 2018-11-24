use Mix.Config

config :chess_db, ChessDb.Repo,
  database: "chess_db_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
