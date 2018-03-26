defmodule CxLeaderboard.Indexer.Stats do
  @moduledoc """
  This module is full of functions that can be used in a custom indexer. Each
  uses a different way of calculating stats. Do you want your ranks to go
  sequentially, like `1, 1, 2`? Then choose one of the `sequential_rank_*`
  functions. Want them offset instead, like `1, 1, 3`? Choose one of the
  `offset_rank_*` functions. If there is something else you want to do that
  isn't available here, you are welcome to implement your own function.

  Most of the functions here are meant to be given as `on_rank` callback. See
  description of each function to find out whether it's intended for `on_rank`
  or `on_entry`.

  The functions used by default are:

      on_rank: &Stats.offset_rank_1_99_less_or_equal_percentile/1
      on_entry: &Stats.global_index/1
  """

  @doc """
  An `on_rank` function. Calculates ranks with an offset (e.g. 1,1,3) and
  percentiles based on all lower scores, and half the equal scores.
  """
  def offset_rank_midpoint_percentile({cnt, _, c_pos, c_size}) do
    rank = c_pos + 1
    lower_scores_count = cnt - c_pos - c_size
    percentile = (lower_scores_count + 0.5 * c_size) / cnt * 100
    {rank, percentile}
  end

  @doc """
  An `on_rank` function. Calculates ranks with an offset (e.g. 1,1,3) and
  percentiles based on all lower scores.
  """
  def offset_rank_less_than_percentile({cnt, _, c_pos, c_size}) do
    rank = c_pos + 1
    lower_scores_count = cnt - c_pos - c_size
    percentile = lower_scores_count / cnt * 100
    {rank, percentile}
  end

  @doc """
  An `on_rank` function. Calculates ranks with an offset (e.g. 1,1,3) and
  percentiles based on all lower and equal scores.
  """
  def offset_rank_less_than_or_equal_percentile({cnt, _, c_pos, _}) do
    rank = c_pos + 1
    same_or_lower_scores_count = cnt - c_pos
    percentile = same_or_lower_scores_count / cnt * 100
    {rank, percentile}
  end

  @doc """
  An `on_rank` function. Calculates ranks with an offset (e.g. 1,1,3) and
  percentiles based on all lower scores and equal scores, then squeezes the
  percentile into 1-99 range.

  This is the default choice.
  """
  def offset_rank_1_99_less_or_equal_percentile({cnt, _, c_pos, _}) do
    rank = c_pos + 1
    same_or_lower_scores_count = cnt - c_pos
    percentile = same_or_lower_scores_count / cnt * 98 + 1
    {rank, percentile}
  end

  @doc """
  An `on_rank` function. Calculates ranks sequentially (e.g. 1,1,2) and
  percentiles based on all lower scores, and half the equal scores.
  """
  def sequential_rank_midpoint_percentile({cnt, c_i, c_pos, c_size}) do
    rank = c_i + 1
    lower_scores_count = cnt - c_pos - c_size
    percentile = (lower_scores_count + 0.5 * c_size) / cnt * 100
    {rank, percentile}
  end

  @doc """
  An `on_rank` function. Calculates ranks sequentially (e.g. 1,1,2) and
  percentiles based on all lower scores.
  """
  def sequential_rank_less_than_percentile({cnt, c_i, c_pos, c_size}) do
    rank = c_i + 1
    lower_scores_count = cnt - c_pos - c_size
    percentile = lower_scores_count / cnt * 100
    {rank, percentile}
  end

  @doc """
  An `on_rank` function. Calculates ranks sequentially (e.g. 1,1,2) and
  percentiles based on all lower and equal scores.
  """
  def sequential_rank_less_than_or_equal_percentile({cnt, c_i, c_pos, _}) do
    rank = c_i + 1
    same_or_lower_scores_count = cnt - c_pos
    percentile = same_or_lower_scores_count / cnt * 100
    {rank, percentile}
  end

  @doc """
  An `on_rank` function. Calculates ranks sequentially (e.g. 1,1,2) and
  percentiles based on all lower scores and equal scores, then squeezes the
  percentile into 1-99 range.
  """
  def sequential_rank_1_99_less_or_equal_percentile({cnt, c_i, c_pos, _}) do
    rank = c_i + 1
    same_or_lower_scores_count = cnt - c_pos
    percentile = same_or_lower_scores_count / cnt * 98 + 1
    {rank, percentile}
  end

  @doc """
  An `on_entry` function. Provides the global index in the leaderboard for each
  record.

  This is the default choice.
  """
  def global_index({i, _, _, _}) do
    i
  end
end
