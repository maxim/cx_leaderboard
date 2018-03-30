defmodule EtsStoreTest do
  use CxLeaderboard.StorageCase
  alias CxLeaderboard.{Leaderboard, EtsStore}

  setup do
    board = Leaderboard.create!(name: :test_board, store: EtsStore)
    {:ok, board: board}
  end

  test "supports storing data source", %{} do
    data = [{-10, :id1}, {-20, :id2}]

    {:ok, _} = Leaderboard.start_link(:global_board, data: data)
    client = Leaderboard.client_for(:global_board)

    top = Leaderboard.top(client) |> Enum.to_list()

    assert [
             {{-20, :id2}, :id2, {0, {1, 99.0}}},
             {{-10, :id1}, :id1, {1, {2, 50.0}}}
           ] == top
  end
end
