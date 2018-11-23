defmodule ChessDbTest do
  use ExUnit.Case
  doctest ChessDb

  test "greets the world" do
    assert ChessDb.hello() == :world
  end
end
