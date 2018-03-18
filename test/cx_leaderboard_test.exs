defmodule CxLeaderboardTest do
  use ExUnit.Case
  doctest CxLeaderboard

  setup do
    board = CxLeaderboard.create(:test_board)
    {:ok, board: board}
  end

  test "keeps entry count", %{board: board} do
    board =
      board
      |> CxLeaderboard.populate([
        {-20, :id1},
        {-30, :id2}
      ])

    assert 2 == CxLeaderboard.count(board)
  end

  test "returns top entries", %{board: board} do
    top =
      board
      |> CxLeaderboard.populate([
        {-20, :id1},
        {-30, :id2}
      ])
      |> CxLeaderboard.top()
      |> Enum.take(2)

    assert [
             {{-30, :id2}, :id2, {0, 1, 75.0, 1, 1}},
             {{-20, :id1}, :id1, {1, 2, 25.0, 0, 1}}
           ] == top
  end

  test "supports payloads in each entry", %{board: board} do
    top =
      board
      |> CxLeaderboard.populate([
        {{-20, :id1}, %{foo: "foo"}},
        {{-30, :id2}, %{bar: "bar"}}
      ])
      |> CxLeaderboard.top()
      |> Enum.take(2)

    assert [
             {{-30, :id2}, %{bar: "bar"}, {0, 1, 75.0, 1, 1}},
             {{-20, :id1}, %{foo: "foo"}, {1, 2, 25.0, 0, 1}}
           ] == top
  end

  test "supports tiebreaks in each entry", %{board: board} do
    top =
      board
      |> CxLeaderboard.populate([
        {-20, 2, :id1},
        {-20, 1, :id2},
        {-30, 3, :id3},
        {-30, 4, :id4}
      ])
      |> CxLeaderboard.top()
      |> Enum.take(4)

    assert [
             {{-30, 3, :id3}, :id3, {0, 1, 75.0, 2, 2}},
             {{-30, 4, :id4}, :id4, {1, 1, 75.0, 2, 2}},
             {{-20, 1, :id2}, :id2, {2, 3, 25.0, 0, 2}},
             {{-20, 2, :id1}, :id1, {3, 3, 25.0, 0, 2}}
           ] == top
  end
end
