defmodule CxLeaderboard.EtsStore.Index do
  # Starting point
  def build(tab, itab, cnt) do
    build(tab, itab, :ets.first(tab), cnt)
  end

  # Table is empty
  defp build(_tab, _itab, :"$end_of_table", _cnt), do: 0

  # Table is not empty
  defp build(tab, itab, key, cnt) do
    build(tab, itab, :ets.next(tab, key), [{key, 0}], 0, 1, cnt)
  end

  # At the end of table
  defp build(
         _tab,
         itab,
         :"$end_of_table",
         buf = [{_, i} | _],
         chunk_pos,
         freq,
         cnt
       ) do
    flush(itab, buf, chunk_pos, freq, cnt)
    i + 1
  end

  defp build(tab, itab, key, buf = [{_, i} | _], chunk_pos, freq, cnt) do
    if score_changed?(key, buf) do
      # flush existing buffer to index table
      flush(itab, buf, chunk_pos, freq, cnt)

      # start a new buffer, and a new chunk position
      build(tab, itab, :ets.next(tab, key), [{key, i + 1}], i + 1, 1, cnt)
    else
      # still within the same chunk, just add to the buffer
      build(
        tab,
        itab,
        :ets.next(tab, key),
        [{key, i + 1} | buf],
        chunk_pos,
        freq + 1,
        cnt
      )
    end
  end

  defp score_changed?({score, _, _}, [{{score, _, _}, _} | _]), do: false
  defp score_changed?({score, _, _}, [{{score,    _}, _} | _]), do: false
  defp score_changed?({score,    _}, [{{score, _, _}, _} | _]), do: false
  defp score_changed?({score,    _}, [{{score,    _}, _} | _]), do: false
  defp score_changed?(_, _), do: true

  defp flush(itab, buf, chunk_pos, freq, cnt) do
    rank = chunk_pos + 1
    lower_scores_count = cnt - chunk_pos - freq
    percentile = (lower_scores_count + 0.5 * freq) / cnt * 100

    buf
    |> Stream.map(fn
      {key = {_, _, id}, i} ->
        {id, key, {i, rank, percentile, lower_scores_count, freq}}

      {key = {_, id}, i} ->
        {id, key, {i, rank, percentile, lower_scores_count, freq}}
    end)
    |> Enum.each(&:ets.insert(itab, &1))
  end
end
