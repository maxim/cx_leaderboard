defmodule CxLeaderboard.TermStore do
  @behaviour CxLeaderboard.Storage

  alias CxLeaderboard.{Indexer, Entry}

  ## Writers

  def create(_) do
    {:ok, %{table: [], index: %{}}}
  end

  def clear(_) do
    {:ok, %{table: [], index: %{}}}
  end

  def populate(_, data) do
    table = Enum.sort(data)
    index = build_index(table)
    {:ok, %{table: table, index: index}}
  end

  def async_populate(_, _) do
    raise "Not implemented"
  end

  def add(%{table: table}, entry) do
    table = Enum.sort([entry | table])
    index = build_index(table)
    {:ok, %{table: table, index: index}}
  end

  def remove(%{table: table, index: index}, id) do
    {_, key, _} = index[id]
    table = List.keydelete(table, key, 0)
    index = build_index(table)
    {:ok, %{table: table, index: index}}
  end

  def update(%{table: table, index: index}, entry) do
    id = Entry.get_id(entry)
    {_, key, _} = index[id]
    table = Enum.sort([entry | List.keydelete(table, key, 0)])
    index = build_index(table)
    {:ok, %{table: table, index: index}}
  end

  def add_or_update(state, entry) do
    id = Entry.get_id(entry)

    case get(state, id) do
      nil -> add(state, entry)
      _ -> update(state, entry)
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

  def range(lb = %{table: table}, id, start..finish) do
    case get(lb, id) do
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
          |> Enum.map(fn entry -> get(lb, Entry.get_id(entry)) end)

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

  def count(%{table: table}) do
    Enum.count(table)
  end

  ## Private

  defp build_index(table) do
    table
    |> Stream.map(fn {key, _} -> key end)
    |> Indexer.index()
    |> Stream.map(fn term = {id, _, _} -> {id, term} end)
    |> Enum.into(%{})
  end
end
