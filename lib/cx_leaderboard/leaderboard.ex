defmodule CxLeaderboard.Leaderboard do
  @enforce_keys [:state, :store]
  defstruct [:state, :store]

  @type state :: term

  alias CxLeaderboard.Entry

  ## Writer functions

  def create(kwargs \\ []) do
    store = Keyword.get(kwargs, :store, CxLeaderboard.EtsStore)

    case store.create(kwargs) do
      {:ok, state} ->
        {:ok, %__MODULE__{state: state, store: store}}

      error ->
        error
    end
  end

  def create!(kwargs \\ []) do
    {:ok, board} = create(kwargs)
    board
  end

  def clear(lb = %__MODULE__{state: state, store: store}) do
    state
    |> store.clear()
    |> update_state(lb)
  end

  def clear!(lb) do
    {:ok, lb} = clear(lb)
    lb
  end

  def populate(lb = %__MODULE__{state: state, store: store}, data) do
    state
    |> store.populate(build_data_stream(data))
    |> update_state(lb)
  end

  def populate!(lb, data) do
    {:ok, lb} = populate(lb, build_data_stream(data))
    lb
  end

  def async_populate(lb = %__MODULE__{state: state, store: store}, data) do
    state
    |> store.async_populate(build_data_stream(data))
    |> update_state(lb)
  end

  def async_populate!(lb, data) do
    {:ok, _} = async_populate(lb, build_data_stream(data))
    lb
  end

  def add(lb = %__MODULE__{state: state, store: store}, entry) do
    case Entry.format(entry) do
      error = {:error, _} ->
        error

      entry ->
        state
        |> store.add(entry)
        |> update_state(lb)
    end
  end

  def add!(lb, entry) do
    {:ok, lb} = add(lb, entry)
    lb
  end

  def update(lb = %__MODULE__{state: state, store: store}, entry) do
    case Entry.format(entry) do
      error = {:error, _} ->
        error

      entry ->
        state
        |> store.update(entry)
        |> update_state(lb)
    end
  end

  def update!(lb, entry) do
    {:ok, lb} = update(lb, entry)
    lb
  end

  def add_or_update(lb = %__MODULE__{state: state, store: store}, entry) do
    case Entry.format(entry) do
      error = {:error, _} ->
        error

      entry ->
        state
        |> store.add_or_update(entry)
        |> update_state(lb)
    end
  end

  def add_or_update!(lb, entry) do
    {:ok, lb} = add_or_update(lb, entry)
    lb
  end

  def remove(lb = %__MODULE__{state: state, store: store}, entry_id) do
    state
    |> store.remove(entry_id)
    |> update_state(lb)
  end

  def remove!(lb, entry_id) do
    {:ok, lb} = remove(lb, entry_id)
    lb
  end

  ## Reader functions

  def top(%__MODULE__{state: state, store: store}) do
    store.top(state)
  end

  def count(%__MODULE__{state: state, store: store}) do
    store.count(state)
  end

  def get(%__MODULE__{state: state, store: store}, entry_id) do
    store.get(state, entry_id)
  end

  def range(%__MODULE__{state: state, store: store}, entry_id, range) do
    store.range(state, entry_id, range)
  end

  ## Private

  defp update_state({:ok, state}, lb), do: {:ok, Map.put(lb, :state, state)}
  defp update_state(error, _), do: error

  defp build_data_stream(data) do
    data
    |> Stream.map(&Entry.format/1)
    |> Stream.reject(fn
      {:error, _} -> true
      _ -> false
    end)
  end
end
