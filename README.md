# ChessDb

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `chess_db` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chess_db, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/chess_db](https://hexdocs.pm/chess_db).

This contains DB for chess games w/ Ecto 3

iex> ChessDb.Repo.delete_all ChessDb.Chess.Game
iex> ChessDb.PgnTools.load_pgn "./test/fixtures/grenke_2018.pgn"