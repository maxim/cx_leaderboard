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
  @type t :: {Entry.key(), Entry.payload(), stats}

  @type stats :: {index, rank, percentile, lower_scores_count, frequency}

  @typedoc """
  The zero-based position of the record in the leaderboard.
  """
  @type index :: non_neg_integer

  @typedoc """
  The rank of the record.
  """
  @type rank :: pos_integer

  @typedoc """
  The percentile of the record based on its rank.
  """
  @type percentile :: float

  @typedoc """
  How many scores in the leaderboard are lesser than the score of this record.
  """
  @type lower_scores_count :: non_neg_integer

  @typedoc """
  How many total records in the leaderboard have the same score as this record.
  """
  @type frequency :: pos_integer

  def get_entry({key, payload, _}), do: {key, payload}
  def get_stats({_, _, stats}), do: stats
end
