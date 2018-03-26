defmodule CxLeaderboard.Record do
  @moduledoc """
  Record is the tuple-based structure that you get back when querying a
  leaderboard. In addition to the stored entry it also carries stats like rank
  and percentile.
  """

  alias CxLeaderboard.Entry

  @typedoc """
  This is how each record comes back to you from the leaderboard. See below for
  breakdowns of each type.
  """
  @type t :: {Entry.key(), Entry.payload(), {entry_stats(), rank_stats()}}

  @typedoc """
  Any entry stats returned by the indexer.
  """
  @type entry_stats :: term

  @typedoc """
  Any rank stats returned by the indexer
  """
  @type rank_stats :: term

  def get_entry({key, payload, _}), do: {key, payload}
  def get_stats({_, _, stats}), do: stats
end
