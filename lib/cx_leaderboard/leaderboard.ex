defmodule CxLeaderboard.Leaderboard do
  @enforce_keys [:id, :store]
  defstruct [:id, :store]

  @typedoc """
  Identifies a specific leaderboard among many.
  """
  @type id :: atom

  @typedoc """
  Use this format when sending your entries to a leaderboard. See below for
  breakdowns of each type.
  """
  @type entry :: key | {key, payload}

  @typedoc """
  This is how each record comes back to you from the leaderboard. See below for
  breakdowns of each type.
  """
  @type record :: {entry_id, key, stats}

  @type key :: {score, entry_id} | {score, tiebreaker, entry_id}

  @typedoc """
  A term on which the leaderboard should be ranked. Any term can work, but
  numeric ones make the most sense.
  """
  @type score :: term

  @typedoc """
  Determines which of the scores appears first if scores are equal. The entry_id
  is always implied as the final tiebreaker, regardless of any other tiebreakers
  provided.
  """
  @type tiebreaker :: term

  @typedoc """
  Must uniquely identify a record in the leaderboard.
  """
  @type entry_id :: term

  @typedoc """
  Allows storing any free-form data with each leaderboard record.
  """
  @type payload :: term

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
end
