defmodule CxLeaderboard.EtsStore do
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
    set_meta(name, {:status, :started})
    {:ok, name}
  end

  def populate(name, data) do
    t1 = :os.system_time(:millisecond)
    set_meta(name, {:status, :updating})

    old_table_name = get_meta(name, :entries_table_name)
    old_index_name = get_meta(name, :index_table_name)

    new_timestamp = :os.system_time(:millisecond)
    entries_table_name = create_entries_table(name, new_timestamp)
    index_table_name = create_index_table(name, new_timestamp)

    data_stream = build_data_stream(data)
    count = Enum.count(data_stream, &:ets.insert(entries_table_name, &1))

    Index.build(entries_table_name, index_table_name, count)

    set_meta(name, [
      {:entries_table_name, entries_table_name},
      {:index_table_name, index_table_name},
      {:status, :normal},
      {:count, count}
    ])

    if old_table_name, do: :ets.delete(old_table_name)
    if old_index_name, do: :ets.delete(old_index_name)

    t2 = :os.system_time(:millisecond)

    {:ok, {count, t2 - t1}}
  end

  # TODO: Refactor this
  def get(name, id) do
    table_name = get_meta(name, :entries_table_name)
    index_name = get_meta(name, :index_table_name)

    if table_name && index_name do
      case lookup(index_name, id) do
        {:ok, index_obj} when is_tuple(index_obj) ->
          case lookup(table_name, elem(index_obj, 1)) do
            {:ok, table_obj} when is_tuple(table_obj) ->
              build_entry(table_obj, index_obj)
            _ ->
              nil
          end

        _ ->
          nil
      end
    else
      nil
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
    |> Stream.map(fn
      entry = {{_, _, _}, _} -> entry
      entry = {{_, _}, _}    -> entry
      entry = {_, _, id}     -> {entry, id}
      entry = {_, id}        -> {entry, id}
    end)
  end

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

  defp create_entries_table(name, timestamp) do
    :ets.new(:"cxlb_#{name}_entries_#{timestamp}", @entries_table_settings)
  end

  defp create_index_table(name, timestamp) do
    :ets.new(:"cxlb_#{name}_index_#{timestamp}", @index_table_settings)
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
end
