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

It allows to import pgn files into db.

iex> ChessDb.Repo.delete_all ChessDb.Chess.Game
iex> ChessDb.PgnTools.load_pgn "./test/fixtures/grenke_2018.pgn"
iex> ChessDb.Import.load_pgn "./test/fixtures/{ivanchuk,Alekhine}.pgn"

Import
==================

One problem is to be able to read huge file, and check pgn validities.

Stream allows to work on huge files (The AepliBase.pgn is > 4Gb)

A pipeline of streams transform raw data into chessfold lexed/parsed structures.
Which in returns are used to create corresponding ecto data.

Stream
==================

```
# Create stream with big file
s = File.stream! "../AepliBase.pgn"  

# Create a stream of header and body
# This will alternate line of tags/elems
s |> Stream.chunk_by(fn line -> String.starts_with?(line, "[") end) |> Stream.chunk_every(2)

# Optional: take a record, flatten, rebuild pgn :-)
|> Enum.take(1) |> List.flatten |> Enum.join()

# And to process tree
|> ChessParser.load_string()
```

The full stream is in chess_db/import/import.ex

Queue worker
==================

A sensitive process...

Using some classical setup, the process was subject to timeout...

-> use an ets table, with one key that store a queue structure
-> ets will allow to bypass genserver call to enqueue/dequeue
-> fifo queue stores events to be processed (list of {:tree, tags, elems})

GenStage
==================

A gen_stage pipeline is set to import pgn concurrently.

one queue, one producer, n consumers

The producer process (Starter) reads and dequeue QueueWorker.
It polls data regularly.

n consumers do the work.

-> extract game_info
-> extract pgn
-> persists game
-> extract sans
-> replay sans (using Chessfold)
-> build positions
-> persists positions, w/ insert_all
-> persists moves, w/ insert_all, and set move's relations w/ positions


