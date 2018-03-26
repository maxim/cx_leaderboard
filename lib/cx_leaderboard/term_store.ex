defmodule CxLeaderboard.TermStore do
  @behaviour CxLeaderboard.Storage

  alias CxLeaderboard.{Indexer, Entry}

  ## Writers

  def create(_) do
    {:ok, %{table: [], index: %{}, count: 0}}
  end

  def clear(_) do
    {:ok, %{table: [], index: %{}, count: 0}}
  end

  def populate(_, data, indexer) do
    table = Enum.sort(data)
    count = Enum.count(data)
    index = build_index(table, count, indexer)
    {:ok, %{table: table, index: index, count: count}}
  end

  def add(state = %{table: table, count: count}, entry, indexer) do
    id = Entry.get_id(entry)

    if get(state, id) do
      {:error, :entry_already_exists}
    else
      table = Enum.sort([entry | table])
      count = count + 1
      index = build_index(table, count, indexer)
      {:ok, %{table: table, index: index, count: count}}
    end
  end

  def remove(
        state = %{
          table: table,
          index: index,
          count: count
        },
        id,
        indexer
      ) do
    if get(state, id) do
      {_, key, _} = index[id]
      table = List.keydelete(table, key, 0)
      count = count - 1
      index = build_index(table, count, indexer)
      {:ok, %{table: table, index: index, count: count}}
    else
      {:error, :entry_not_found}
    end
  end

  def update(
        state = %{table: table, index: index, count: count},
        entry,
        indexer
      ) do
    id = Entry.get_id(entry)

    if get(state, id) do
      {_, key, _} = index[id]
      table = Enum.sort([entry | List.keydelete(table, key, 0)])
      index = build_index(table, count, indexer)
      {:ok, %{table: table, index: index}}
    else
      {:error, :entry_not_found}
    end
  end

  def add_or_update(state, entry, indexer) do
    id = Entry.get_id(entry)

    case get(state, id) do
      nil -> add(state, entry, indexer)
      _ -> update(state, entry, indexer)
    end
  end

  ## Readers

  def get(%{table: table, index: index}, id) do
    with {_, key, stats} <- index[id],
         {_, payload} <- List.keyfind(table, key, 0) do
      {key, payload, stats}
    else
      _ -> nil
    end
  end

  def get(state = %{table: table}, id, start..finish) do
    case get(state, id) do
      nil ->
        []

      {key, _, _} ->
        key_index =
          table
          |> Enum.find_index(fn
            {^key, _} -> true
            _ -> false
          end)

        {min, max} = Enum.min_max([start, finish])

        min_index = Enum.max([key_index + min, 0])
        max_index = Enum.max([key_index + max, 0])

        slice =
          table
          |> Enum.slice(min_index..max_index)
          |> Enum.map(fn entry -> get(state, Entry.get_id(entry)) end)

        if finish < start, do: Enum.reverse(slice), else: slice
    end
  end

  def top(state = %{table: table}) do
    table
    |> Stream.map(fn entry ->
      id = Entry.get_id(entry)
      get(state, id)
    end)
  end

  def bottom(state = %{table: table}) do
    table
    |> Enum.reverse()
    |> Stream.map(fn entry ->
      id = Entry.get_id(entry)
      get(state, id)
    end)
  end

  def count(%{count: count}) do
    count
  end

  ## Private

  defp build_index(table, count, indexer) do
    table
    |> Stream.map(fn {key, _} -> key end)
    |> Indexer.index(count, indexer)
    |> Stream.map(fn term = {id, _, _} -> {id, term} end)
    |> Enum.into(%{})
  end
end
