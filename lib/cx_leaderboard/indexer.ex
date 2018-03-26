defmodule CxLeaderboard.Indexer do
  @moduledoc """
  Indexer walks the entire leaderboard and calculates the needed stats, such as
  rank and percentile.

  You can customize the stats by creating a custom indexer — a struct consisting
  of 2 callback functions:

    - `on_rank` is called when the indexer finishes scanning a set of equal
      scores, and moves onto a lower score

    - `on_entry` is called for every entry

  It's important to avoid doing anything `on_entry` that can instead be done
  `on_rank`, since we don't want to unnecessarily slow down the indexer.

  This library comes with a bunch of pre-made `on_rank` functions for different
  flavor of rank and percentile calculation. See `CxLeaderboard.Indexer.Stats`
  documentation for what's available.

  ## The on_rank callback

  Indexer walks through the sorted dataset of all entries from the highest to
  the lowest score. Every time a score is different between entries, it runs the
  `on_rank` callback for the rank it just finished scanning. The return value of
  the function is added to every record in the rank it just walked.

  The function receives the following tuple as the argument:

      {total_leadeboard_size, chunk_index, chunk_position, chunk_size}

    - `total_leaderboard_size` - total number of entries in the leaderboard
    - `chunk_index` - zero-based counter for how many different ranks we have
      seen so far
    - `chunk_position` - zero-based position where this rank started in the
      leaderboard
    - `chunk_size` - how many equal scores are in this rank

  Based on these values the function can perform any kind of calculation and
  return any term as a result.

  Let's see an example of walking through a mini-leaderboard, and see what
  numbers get passed into the `on_rank` function.

      walking  score   total_size   chunk_index  chunk_position  chunk_size
         |       3        n/a           n/a           n/a           n/a
         |       3         6             0             0             2
         |       2        n/a           n/a           n/a           n/a
         |       2        n/a           n/a           n/a           n/a
         |       2         6             1             2             3
         V       1         6             2             5             1

  As the indexer walks the leaderboard, it will only call the `on_rank` function
  on the rows where score is about to change, therefore some of the rows are
  marked n/a.

  ## The on_entry callback

  An `on_entry` callback is similar to `on_rank` but it receives different
  parameters, and it's called on every entry. Its result is added to the entry
  for which it's called.

  The function receives the following tuple as the argument:

      {entry_index, entry_id, entry_key, rank_stats}

    - `entry_index` - global position in the leaderboard (top is 0)
    - `entry_id` - the id used for fetching records
    - `entry_key` - either `{score, id}` or `{score, tiebreaker, id}` depending
      on what was inserted
    - `rank_stats` - the return value of the `on_rank` function

  Due to `rank_stats` parameter it's possible to make more granular calculations
  based on whatever was provided by the `on_rank` function.
  """

  alias CxLeaderboard.Indexer.Stats
  alias CxLeaderboard.Entry

  defstruct on_rank: &Stats.offset_rank_1_99_less_or_equal_percentile/1,
            on_entry: &Stats.global_index/1

  @type t :: %__MODULE__{
          on_rank: Indexer.on_rank(),
          on_entry: Indexer.on_entry()
        }

  @type on_rank ::
          ({
             non_neg_integer,
             non_neg_integer,
             non_neg_integer,
             non_neg_integer
           } ->
             term)

  @type on_entry :: ({non_neg_integer, term, Entry.key(), term} -> term)

  def index(keys) do
    index(keys, Enum.count(keys))
  end

  def index(keys, cnt) do
    index(keys, cnt, %__MODULE__{})
  end

  def index(_, 0, _), do: []

  def index(keys, cnt, indexer) do
    keys
    |> Stream.chunk_while(
      {indexer, cnt},
      &rank_split/2,
      &rank_done/1
    )
    |> Stream.concat()
  end

  defp rank_split(key, {indexer, cnt}) do
    {:cont, {indexer, cnt, 0, 0, 1, [{key, 0}]}}
  end

  defp rank_split(
         key,
         acc = {indexer, cnt, c_i, c_pos, c_size, buf = [{_, i} | _]}
       ) do
    if score_changed?(key, buf) do
      {:cont, flush(acc), {indexer, cnt, c_i + 1, i + 1, 1, [{key, i + 1}]}}
    else
      {:cont, {indexer, cnt, c_i, c_pos, c_size + 1, [{key, i + 1} | buf]}}
    end
  end

  defp rank_done({_, _, _, []}), do: {:cont, []}
  defp rank_done(acc), do: {:cont, flush(acc), {}}

  defp score_changed?({score, _, _}, [{{score, _, _}, _} | _]), do: false
  defp score_changed?({score, _, _}, [{{score, _}, _} | _]), do: false
  defp score_changed?({score, _}, [{{score, _, _}, _} | _]), do: false
  defp score_changed?({score, _}, [{{score, _}, _} | _]), do: false
  defp score_changed?(_, _), do: true

  defp flush({indexer, cnt, c_i, c_pos, c_size, buf}) do
    rank_stats = indexer.on_rank.({cnt, c_i, c_pos, c_size})

    Stream.map(buf, fn
      {key = {_, _, id}, i} ->
        {id, key, {indexer.on_entry.({i, id, key, rank_stats}), rank_stats}}

      {key = {_, id}, i} ->
        {id, key, {indexer.on_entry.({i, id, key, rank_stats}), rank_stats}}
    end)
  end
end
