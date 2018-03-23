defmodule EtsStoreTest do
  use CxLeaderboard.StorageCase
  alias CxLeaderboard.{Leaderboard, EtsStore}

  setup do
    board = Leaderboard.create!(name: :test_board, store: EtsStore)
    {:ok, board: board}
  end
end
