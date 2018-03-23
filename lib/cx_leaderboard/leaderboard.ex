defmodule CxLeaderboard.Leaderboard do
  @enforce_keys [:state, :store]
  defstruct [:state, :store]

  @type t :: %__MODULE__{state: state(), store: module()}
  @type state :: term

  alias CxLeaderboard.{Leaderboard, Entry, Record}

  ## Writer functions

  @spec create(keyword()) :: {:ok, Leaderboard.t()} | {:error, term}
  def create(kwargs \\ []) do
    store = Keyword.get(kwargs, :store, CxLeaderboard.EtsStore)

    case store.create(kwargs) do
      {:ok, state} ->
        {:ok, %__MODULE__{state: state, store: store}}

      error ->
        error
    end
  end

  @spec create!(keyword()) :: Leaderboard.t()
  def create!(kwargs \\ []) do
    {:ok, board} = create(kwargs)
    board
  end

  @spec clear(Leaderboard.t()) :: {:ok, Leaderboard.t()} | {:error, term}
  def clear(lb = %__MODULE__{state: state, store: store}) do
    state
    |> store.clear()
    |> update_state(lb)
  end

  @spec clear!(Leaderboard.t()) :: Leaderboard.t()
  def clear!(lb) do
    {:ok, lb} = clear(lb)
    lb
  end

  @spec populate(Leaderboard.t(), Enumerable.t()) ::
          {:ok, Leaderboard.t()} | {:error, term}
  def populate(lb = %__MODULE__{state: state, store: store}, data) do
    state
    |> store.populate(build_data_stream(data))
    |> update_state(lb)
  end

  @spec populate!(Leaderboard.t(), Enumerable.t()) :: Leaderboard.t()
  def populate!(lb, data) do
    {:ok, lb} = populate(lb, build_data_stream(data))
    lb
  end

  @spec async_populate(Leaderboard.t(), Enumerable.t()) ::
          {:ok, Leaderboard.t()} | {:error, term}
  def async_populate(lb = %__MODULE__{state: state, store: store}, data) do
    state
    |> store.async_populate(build_data_stream(data))
    |> update_state(lb)
  end

  @spec async_populate!(Leaderboard.t(), Enumerable.t()) :: Leaderboard.t()
  def async_populate!(lb, data) do
    {:ok, _} = async_populate(lb, build_data_stream(data))
    lb
  end

  @spec add(Leaderboard.t(), Entry.t()) ::
          {:ok, Leaderboard.t()} | {:error, term}
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

  @spec add!(Leaderboard.t(), Entry.t()) :: Leaderboard.t()
  def add!(lb, entry) do
    {:ok, lb} = add(lb, entry)
    lb
  end

  @spec update(Leaderboard.t(), Entry.t()) ::
          {:ok, Leaderboard.t()} | {:error, term}
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

  @spec update!(Leaderboard.t(), Entry.t()) :: Leaderboard.t()
  def update!(lb, entry) do
    {:ok, lb} = update(lb, entry)
    lb
  end

  @spec add_or_update(Leaderboard.t(), Entry.t()) ::
          {:ok, Leaderboard.t()} | {:error, term}
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

  @spec add_or_update!(Leaderboard.t(), Entry.t()) :: Leaderboard.t()
  def add_or_update!(lb, entry) do
    {:ok, lb} = add_or_update(lb, entry)
    lb
  end

  @spec remove(Leaderboard.t(), Entry.id()) ::
          {:ok, Leaderboard.t()} | {:error, term}
  def remove(lb = %__MODULE__{state: state, store: store}, entry_id) do
    state
    |> store.remove(entry_id)
    |> update_state(lb)
  end

  @spec remove!(Leaderboard.t(), Entry.id()) :: Leaderboard.t()
  def remove!(lb, entry_id) do
    {:ok, lb} = remove(lb, entry_id)
    lb
  end

  ## Reader functions

  @spec top(Leaderboard.t()) :: Enumerable.t()
  def top(%__MODULE__{state: state, store: store}) do
    store.top(state)
  end

  @spec bottom(Leaderboard.t()) :: Enumerable.t()
  def bottom(%__MODULE__{state: state, store: store}) do
    store.bottom(state)
  end

  @spec count(Leaderboard.t()) :: non_neg_integer
  def count(%__MODULE__{state: state, store: store}) do
    store.count(state)
  end

  @spec get(Leaderboard.t(), Entry.id()) :: Record.t()
  def get(%__MODULE__{state: state, store: store}, entry_id) do
    store.get(state, entry_id)
  end

  @spec range(Leaderboard.t(), Entry.id(), Range.t()) :: [Record.t()]
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
