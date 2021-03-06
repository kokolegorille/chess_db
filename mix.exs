defmodule ChessDb.MixProject do
  use Mix.Project

  def project do
    [
      app: :chess_db,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ChessDb.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.1"},
      {:ecto_enum, "~> 1.1"},
      #
      {:gen_stage, "~> 0.14.1"},
      #
      {:chess_parser, git: "https://github.com/kokolegorille/chess_parser.git"},
      {:chessfold, git: "https://github.com/kokolegorille/chessfold"},
      {:iconv, "~> 1.0"},
    ]
  end
end
