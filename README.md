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

iex> ChessDb.Import.load_pgn "./test/fixtures/{ivanchuk,Alekhine}.pgn"


Stream

# Create stream with big file
s = File.stream! "../AepliBase.pgn"  

# Create a stream of header and body
# This will alternate line of tags/elems
s |> Stream.chunk_by(fn line -> String.starts_with?(line, "[") end) |> Stream.chunk_every(2)

# Optional: take a record, flatten, rebuild pgn :-)
|> Enum.take(1) |> List.flatten |> Enum.join()

# And to process tree
|> ChessParser.load_string()