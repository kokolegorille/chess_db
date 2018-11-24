use Mix.Config

config :chess_db, ChessDb.Repo,
  database: "chess_db_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
