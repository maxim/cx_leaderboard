defmodule CxLeaderboard do
  @moduledoc """
  Here is an example of how you can create and manage a leaderboard.

      alias CxLeaderboard.Leaderboard

      # Create a leaderboard
      {:ok, board} = Leaderboard.create(:global)

      # Put data into it
      Leaderboard.populate!(board, [
        {-20, :id1},
        {-30, :id2}
      ])

      records =
        Leaderboard.top(board)
        |> Enum.take(2)

      # Records
      # {{-30, :id2}, :id2, {0, 1, 75.0, 1, 1}},
      # {{-20, :id1}, :id1, {1, 2, 25.0, 0, 1}}

      Leaderboard.update!(board, {-10, :id2})

      records =
        Leaderboard.top(board)
        |> Enum.take(2)

      # Records
      # {{-20, :id1}, :id1, {0, 1, 75.0, 1, 1}},
      # {{-10, :id2}, :id2, {1, 2, 25.0, 0, 1}}

  TODO:

    - [DONE] Rewrite Index.build
    - [DONE] Allow add/remove entries (rebuild only index) but still leave
      populate() function for initial setup
    - [DONE] Decide how to handle invalid entries
    - [DONE] Move Server logic under EtsStore
    - [DONE] Formalize storage as a behaviour
    - [DONE] Implement update function
    - [DONE] Move data stream processing (and format_entry) out of storage
    - [DONE] Add add_or_update for more efficient upsert
    - [DONE] Add get top-level function
    - [DONE] Implement scoping by ids (this is now possible with TermStore)
    - Implement "around" featureset
    - Implement status fetching
    - Add benchmark
    - Figure out how to reuse this library at Crossfield
    - Docs
    - Typespecs
    - More tests
  """

  @doc """
  Hello world.

  ## Examples

      iex> CxLeaderboard.hello
      :world

  """
  def hello do
    :world
  end
end
