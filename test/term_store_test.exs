defmodule TermStoreTest do
  use CxLeaderboard.StorageCase
  alias CxLeaderboard.{Leaderboard, TermStore}

  setup do
    board = Leaderboard.create!(store: TermStore)
    {:ok, board: board}
  end
end
