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

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create!(kwargs \\ []) do
    {:ok, board} = create(kwargs)
    board
  end

  def clear(lb = %__MODULE__{state: state, store: store}) do
    case store.clear(state) do
      {:ok, state} ->
        {:ok, Map.put(lb, :state, state)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def clear!(lb) do
    {:ok, _} = clear(lb)
    lb
  end

  def populate(%__MODULE__{state: state, store: store}, data) do
    store.populate(state, build_data_stream(data))
  end

  def populate!(lb, data) do
    {:ok, _} = populate(lb, build_data_stream(data))
    lb
  end

  def async_populate(%__MODULE__{state: state, store: store}, data) do
    store.async_populate(state, build_data_stream(data))
  end

  def async_populate!(lb, data) do
    {:ok, _} = async_populate(lb, build_data_stream(data))
    lb
  end

  def add(%__MODULE__{state: state, store: store}, entry) do
    case Entry.format(entry) do
      error = {:error, _} -> error
      entry -> store.add(state, entry)
    end
  end

  def add!(lb, entry) do
    {:ok, _} = add(lb, entry)
    lb
  end

  def update(%__MODULE__{state: state, store: store}, entry) do
    case Entry.format(entry) do
      error = {:error, _} -> error
      entry -> store.update(state, entry)
    end
  end

  def update!(lb, entry) do
    {:ok, _} = update(lb, entry)
    lb
  end

  def add_or_update(%__MODULE__{state: state, store: store}, entry) do
    case Entry.format(entry) do
      error = {:error, _} -> error
      entry -> store.add_or_update(state, entry)
    end
  end

  def add_or_update!(lb, entry) do
    {:ok, _} = add_or_update(lb, entry)
    lb
  end

  def remove(%__MODULE__{state: state, store: store}, entry_id) do
    store.remove(state, entry_id)
  end

  def remove!(lb, entry_id) do
    {:ok, _} = remove(lb, entry_id)
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

  ## Private

  defp build_data_stream(data) do
    data
    |> Stream.map(&Entry.format/1)
    |> Stream.reject(fn
      {:error, _} -> true
      _ -> false
    end)
  end
end
