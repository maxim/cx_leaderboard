defmodule CxLeaderboard.Indexer do
  def index(keys) do
    index(keys, Enum.count(keys))
  end

  def index(_, 0), do: []

  def index(keys, cnt) do
    keys
    |> Stream.chunk_while({cnt}, &rank_split/2, &rank_done/1)
    |> Stream.concat()
  end

  defp rank_split(key, {cnt}) do
    {:cont, {cnt, 0, 1, [{key, 0}]}}
  end

  defp rank_split(key, acc = {cnt, c_pos, c_size, buf = [{_, i} | _]}) do
    if score_changed?(key, buf) do
      {:cont, flush(acc), {cnt, i + 1, 1, [{key, i + 1}]}}
    else
      {:cont, {cnt, c_pos, c_size + 1, [{key, i + 1} | buf]}}
    end
  end

  defp rank_done({_, _, _, []}), do: {:cont, []}
  defp rank_done(acc), do: {:cont, flush(acc), {}}

  defp score_changed?({score, _, _}, [{{score, _, _}, _} | _]), do: false
  defp score_changed?({score, _, _}, [{{score, _}, _} | _]), do: false
  defp score_changed?({score, _}, [{{score, _, _}, _} | _]), do: false
  defp score_changed?({score, _}, [{{score, _}, _} | _]), do: false
  defp score_changed?(_, _), do: true

  defp flush({cnt, c_pos, c_size, buf}) do
    rank = c_pos + 1
    lower_scores_count = cnt - c_pos - c_size
    percentile = (lower_scores_count + 0.5 * c_size) / cnt * 100

    Stream.map(buf, fn
      {key = {_, _, id}, i} ->
        {id, key, {i, rank, percentile, lower_scores_count, c_size}}

      {key = {_, id}, i} ->
        {id, key, {i, rank, percentile, lower_scores_count, c_size}}
    end)
  end
end
