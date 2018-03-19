defmodule CxLeaderboard.EtsStore.Ets do
  alias CxLeaderboard.EtsStore.Index

  @meta_table_settings [
    :set,
    :named_table,
    :protected,
    read_concurrency: true
  ]

  @entries_table_settings [
    :ordered_set,
    :named_table,
    :protected,
    read_concurrency: true
  ]

  @index_table_settings [
    :set,
    :named_table,
    :protected,
    read_concurrency: true
  ]

  def init(name) do
    create_meta_table(name)

    set_meta(name, [
      {:entries_table_name, create_entries_table(name)},
      {:index_table_name, create_index_table(name)},
      {:status, :started},
      {:count, 0}
    ])

    {:ok, name}
  end

  def add(name, entry) do
    case format_entry(entry) do
      {:error, reason} ->
        {:error, reason}

      formatted_entry ->
        modify_with_reindex(name, +1, fn table ->
          :ets.insert(table, formatted_entry)
        end)
    end
  end

  def remove(name, id) do
    case get(name, id) do
      {key, _, _} ->
        modify_with_reindex(name, -1, fn table ->
          :ets.delete(table, key)
        end)

      _ ->
        {:error, :key_not_found}
    end
  end

  def populate(name, data) do
    t1 = get_timestamp()
    set_meta(name, {:status, :populating})

    old_table = get_meta(name, :entries_table_name)
    old_index = get_meta(name, :index_table_name)

    suffix = get_rand_suffix()

    {new_table, count} = insert_entries(name, data, suffix)
    new_index = build_index(name, new_table, count, suffix)

    set_meta(name, [
      {:entries_table_name, new_table},
      {:index_table_name, new_index},
      {:status, :normal},
      {:count, count}
    ])

    if old_table, do: :ets.delete(old_table)
    if old_index, do: :ets.delete(old_index)

    t2 = get_timestamp()
    {:ok, {count, t2 - t1}}
  end

  def get(name, id) do
    with table when not is_nil(table) <- get_meta(name, :entries_table_name),
         index when not is_nil(index) <- get_meta(name, :index_table_name),
         {:ok, index_term = {_, key, _}} <- lookup(index, id),
         {:ok, table_term = {_, _}} <- lookup(table, key) do
      build_entry(table_term, index_term)
    else
      _ -> nil
    end
  end

  def top(name) do
    table_name = get_meta(name, :entries_table_name)

    if table_name do
      stream_keys(table_name)
      |> Stream.map(fn
        {_, _, id} -> get(name, id)
        {_, id} -> get(name, id)
      end)
    else
      []
    end
  end

  def count(name) do
    get_meta(name, :count)
  end

  ## Private

  defp modify_with_reindex(name, count_change, modification) do
    t1 = get_timestamp()
    set_meta(name, {:status, :reindexing})

    table = get_meta(name, :entries_table_name)
    old_index = get_meta(name, :index_table_name)
    new_count = get_meta(name, :count) + count_change

    modification.(table)

    new_index = build_index(name, table, new_count)

    set_meta(name, [
      {:index_table_name, new_index},
      {:status, :normal},
      {:count, new_count}
    ])

    if old_index, do: :ets.delete(old_index)

    t2 = get_timestamp()
    {:ok, {new_count, t2 - t1}}
  end

  defp insert_entries(name, data, suffix) do
    table = create_entries_table(name, suffix)
    data_stream = build_data_stream(data)
    count = Enum.count(data_stream, &:ets.insert(table, &1))
    {table, count}
  end

  defp build_index(name, table, count, suffix \\ get_rand_suffix()) do
    index = create_index_table(name, suffix)
    Index.build(table, index, count)
    index
  end

  defp build_entry({key, payload}, {_, _, stats}) do
    {key, payload, stats}
  end

  defp stream_keys(table_name) do
    Stream.unfold(:ets.first(table_name), fn
      :"$end_of_table" -> nil
      key -> {key, :ets.next(table_name, key)}
    end)
  end

  defp build_data_stream(data) do
    data
    |> Stream.map(&format_entry/1)
    |> Stream.reject(fn
      {:error, _} -> true
      _ -> false
    end)
  end

  defp format_entry(entry = {{_, _, _}, _}), do: entry
  defp format_entry(entry = {{_, _}, _}), do: entry
  defp format_entry(entry = {_, _, id}), do: {entry, id}
  defp format_entry(entry = {_, id}), do: {entry, id}
  defp format_entry(_), do: {:error, :bad_entry}

  defp set_meta(name, record) do
    name
    |> meta_table_name()
    |> :ets.insert(record)
  end

  defp get_meta(name, key) do
    table_name = meta_table_name(name)

    case :ets.info(table_name) do
      :undefined ->
        nil

      _ ->
        case lookup(table_name, key) do
          {:ok, nil} -> nil
          {:ok, {_, value}} -> value
        end
    end
  end

  defp meta_table_name(name) do
    :"cxlb_#{name}_meta"
  end

  defp create_meta_table(name) do
    name |> meta_table_name() |> :ets.new(@meta_table_settings)
  end

  defp create_entries_table(name, suffix \\ get_rand_suffix()) do
    :ets.new(:"cxlb_#{name}_entries_#{suffix}", @entries_table_settings)
  end

  defp create_index_table(name, suffix \\ get_rand_suffix()) do
    :ets.new(:"cxlb_#{name}_index_#{suffix}", @index_table_settings)
  end

  defp lookup(table_name, key) do
    case :ets.lookup(table_name, key) do
      [] ->
        {:ok, nil}

      [value] ->
        {:ok, value}

      error ->
        error
    end
  end

  defp get_timestamp do
    :os.system_time(:millisecond)
  end

  defp get_rand_suffix(bytes \\ 10) do
    1..bytes
    |> Enum.map(fn _ -> :rand.uniform(255) end)
    |> :binary.list_to_bin()
    |> Base.url_encode64(padding: false)
  end
end
