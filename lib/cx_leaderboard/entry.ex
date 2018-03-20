defmodule CxLeaderboard.Entry do
  @moduledoc """
  Entry is the tuple-based structure that you send into the leaderboard.
  """

  @typedoc """
  Use this format when sending your entries to a leaderboard. See below for
  breakdowns of each type.
  """
  @type t :: {key, payload}

  @type key :: {score, id} | {score, tiebreaker, id}

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
  @type id :: term

  @typedoc """
  Allows storing any free-form data with each leaderboard record.
  """
  @type payload :: term

  def format(input = {{_, _, _}, _}), do: input
  def format(input = {{_, _}, _}), do: input
  def format(input = {_, _, id}), do: {input, id}
  def format(input = {_, id}), do: {input, id}
  def format(_), do: {:error, :bad_entry}

  def get_score({{score, _, _}, _}), do: score
  def get_score({{score, _}, _}), do: score

  def get_tiebreak({{_, tiebreak, _}, _}), do: tiebreak
  def get_tiebreak({{_, _}, _}), do: nil

  def get_id({{_, _, id}, _}), do: id
  def get_id({{_, id}, _}), do: id

  def get_payload({_, payload}), do: payload
end
