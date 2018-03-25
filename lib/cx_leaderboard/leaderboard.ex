defmodule CxLeaderboard.Leaderboard do
  @moduledoc """

  Leaderboard is a lightweight database designed to optimize storing and sorting
  data based on ranked scores. It has the following abilities:

    - Create any number of leaderboards.
    - Store scores and payloads.
    - Calculate ranks, percentiles, and other stats.
    - Provide a sorted stream of all records.
    - Support custom tie-breakers for records of the same rank.
    - Provide a range of records around a specific id (contextual leaderboard).
    - Add/remove/update/upsert individual records in an existing leaderboard.
    - Re-populate the leaderboard with asynchrony and atomicity.
    - Build mini-leaderboards contained in simple elixir structs.

  In order to fill a leaderboard you need to have an enumerable of all your
  entries.

  ## Entry

  An entry is a structure that you populate into the leaderboard. The shape of
  an entry can be one of the following:

    * `{score, id}`
    * `{score, tiebreaker, id}`
    * `{{score, id}, payload}`
    * `{{score, tiebreaker, id}, payload}`

  A `score` can be any term — elixir will use it for sorting and ranking.

  A `tiebreaker` comes in handy when you know that you will have multiple
  records of the same rank, and you'd like to use additional criteria to sort
  them in the leaderboard.

  An `id` is any term that uniquely identifies a record, and that you will be
  using to `get` them. Id is always the last tiebreaker.

  A `payload` is any term that you'd like to store with your record. Use it for
  everything you need to display the leaderboard. If not provided, `id` will be
  used as the payload.

  ## Record

  A record is what you get back when querying the leaderboard. It contains both
  your entry, and calculated stats. Here's what it looks like:

      {{score, id}, payload, stats} # without tiebreaker
      {{score, tiebreaker, id}, payload, stats} # with tiebreaker

  ## Stats

  The stats is a tuple with the following fields (in their respective order):

    * `index` - zero-based position of the record in the leaderboard, where 0 is
      the top.
    * `rank` - rank of the score in the leaderboard, where 1 is the top rank.
      Ranks are offset by the number of records possessing them. E.g.: if 2
      entries have rank 1, then the next record will have rank 3.
    * `percentile` - what percent of records have lower score than this one.
    * `lower_scores_count` - how many records have lower scores than this one.
    * `frequency` - how many records have the same score as this one.

  """

  @enforce_keys [:state, :store]
  defstruct [:state, :store]

  @type t :: %__MODULE__{state: state(), store: module()}
  @type state :: term

  alias CxLeaderboard.{Leaderboard, Entry, Record}

  ## Writer functions

  @doc """
  Creates a new leaderboard.

  ## Options

    * `:store` - storage engine to use for the leaderboard. Supports
      `CxLeaderboard.EtsStore` and `CxLeaderboard.TermStore`. Default:
      `CxLeaderboard.EtsStore`.

    * `:name` - sets the name identifying the leaderboard. Only needed when
      using `CxLeaderboard.EtsStore`.

  ## Examples

      iex> Leaderboard.create(name: :global)
      {:ok, %Leaderboard{state: :global, store: CxLeaderboard.EtsStore}}
  """
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

  @doc """
  Same as `create/1` but returns the leaderboard or raises an error.
  """
  @spec create!(keyword()) :: Leaderboard.t()
  def create!(kwargs \\ []) do
    {:ok, board} = create(kwargs)
    board
  end

  @doc """
  Clears the data from a leaderboard.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.populate(board, [{-2, :id1}, {-3, :id2}])
      iex> Leaderboard.count(board)
      2
      iex> {:ok, board} = Leaderboard.clear(board)
      iex> Leaderboard.count(board)
      0
  """
  @spec clear(Leaderboard.t()) :: {:ok, Leaderboard.t()} | {:error, term}
  def clear(lb = %__MODULE__{state: state, store: store}) do
    state
    |> store.clear()
    |> update_state(lb)
  end

  @doc """
  Same as `clear/1` but returns the leaderboard or raises.
  """
  @spec clear!(Leaderboard.t()) :: Leaderboard.t()
  def clear!(lb) do
    {:ok, lb} = clear(lb)
    lb
  end

  @doc """
  Populates a leaderboard with entries. Invalid entries are silently skipped.

  See Entry section of the module doc for information about entries.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.populate(board, [{-2, :id1}, {-3, :id2}])
      iex> Leaderboard.count(board)
      2
  """
  @spec populate(Leaderboard.t(), Enumerable.t()) ::
          {:ok, Leaderboard.t()} | {:error, term}
  def populate(lb = %__MODULE__{state: state, store: store}, data) do
    state
    |> store.populate(build_data_stream(data))
    |> update_state(lb)
  end

  @doc """
  Same as `populate/2` but returns the leaderboard or raises.
  """
  @spec populate!(Leaderboard.t(), Enumerable.t()) :: Leaderboard.t()
  def populate!(lb, data) do
    {:ok, lb} = populate(lb, build_data_stream(data))
    lb
  end

  @doc """
  Populates a leaderboard with entries asynchronously. Only works with EtsStore.
  Invalid entries are silently skipped.

  See Entry section of the module doc for information about entries.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.async_populate(board, [
      ...>   {-2, :id1},
      ...>   {-3, :id2}
      ...> ])
      iex> Leaderboard.count(board)
      0
      iex> :timer.sleep(100)
      iex> Leaderboard.count(board)
      2
  """
  @spec async_populate(Leaderboard.t(), Enumerable.t()) ::
          {:ok, Leaderboard.t()} | {:error, term}
  def async_populate(lb = %__MODULE__{state: state, store: store}, data) do
    state
    |> store.async_populate(build_data_stream(data))
    |> update_state(lb)
  end

  @doc """
  Same as `async_populate/2` but returns the leaderboard or raises.
  """
  @spec async_populate!(Leaderboard.t(), Enumerable.t()) :: Leaderboard.t()
  def async_populate!(lb, data) do
    {:ok, _} = async_populate(lb, build_data_stream(data))
    lb
  end

  @doc """
  Adds a single entry to an existing leaderboard. Invalid entries will return an
  error. If the id already exists, will return an error.

  See Entry section of the module doc for information about entries.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.add(board, {-1, :id1})
      iex> Leaderboard.count(board)
      1
      iex> Leaderboard.add(board, :invalid_entry)
      {:error, :bad_entry}
      iex> Leaderboard.add(board, {-1, :id1})
      {:error, :entry_already_exists}
  """
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

  @doc """
  Same as `add/2` but returns the leaderboard or raises.
  """
  @spec add!(Leaderboard.t(), Entry.t()) :: Leaderboard.t()
  def add!(lb, entry) do
    {:ok, lb} = add(lb, entry)
    lb
  end

  @doc """
  Updates a single entry in an existing leaderboard. Invalid entries will return
  an error. If the id is not in the leaderboard, will return an error.

  See Entry section of the module doc for information about entries.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.populate(board, [{-2, :id1}, {-3, :id2}])
      iex> {:ok, board} = Leaderboard.update(board, {-5, :id1})
      iex> Leaderboard.get(board, :id1)
      {{-5, :id1}, :id1, {0, 1, 75.0, 1, 1}}
      iex> Leaderboard.update(board, {-2, :missing_id})
      {:error, :entry_not_found}
  """
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

  @doc """
  Same as `update/2` but returns the leaderboard or raises.
  """
  @spec update!(Leaderboard.t(), Entry.t()) :: Leaderboard.t()
  def update!(lb, entry) do
    {:ok, lb} = update(lb, entry)
    lb
  end

  @doc """
  Updates an entry in an existing leaderboard, or adds it if the id doesn't
  exist. Invalid entries will return an error.

  See Entry section of the module doc for information about entries.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.add_or_update(board, {1, :id1})
      iex> Leaderboard.get(board, :id1)
      {{1, :id1}, :id1, {0, 1, 50.0, 0, 1}}
      iex> {:ok, board} = Leaderboard.add_or_update(board, {2, :id1})
      iex> Leaderboard.get(board, :id1)
      {{2, :id1}, :id1, {0, 1, 50.0, 0, 1}}
  """
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

  @doc """
  Same as `add_or_update/2` but returns the leaderboard or raises.
  """
  @spec add_or_update!(Leaderboard.t(), Entry.t()) :: Leaderboard.t()
  def add_or_update!(lb, entry) do
    {:ok, lb} = add_or_update(lb, entry)
    lb
  end

  @doc """
  Removes an entry from a leaderboard by id. If the id is not in the
  leaderboard, will return an error.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.populate(board, [{-2, :id1}, {-3, :id2}])
      iex> {:ok, board} = Leaderboard.remove(board, :id1)
      iex> Leaderboard.count(board)
      1
      iex> Leaderboard.remove(board, :id1)
      {:error, :entry_not_found}
  """
  @spec remove(Leaderboard.t(), Entry.id()) ::
          {:ok, Leaderboard.t()} | {:error, term}
  def remove(lb = %__MODULE__{state: state, store: store}, entry_id) do
    state
    |> store.remove(entry_id)
    |> update_state(lb)
  end

  @doc """
  Same as `remove/2` but returns the leaderboard or raises.
  """
  @spec remove!(Leaderboard.t(), Entry.id()) :: Leaderboard.t()
  def remove!(lb, entry_id) do
    {:ok, lb} = remove(lb, entry_id)
    lb
  end

  ## Reader functions

  @doc """
  Returns a stream of top leaderboard records.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.populate(board, [{-2, :id1}, {-3, :id2}])
      iex> Leaderboard.top(board) |> Enum.take(1)
      [{{-3, :id2}, :id2, {0, 1, 75.0, 1, 1}}]
  """
  @spec top(Leaderboard.t()) :: Enumerable.t()
  def top(%__MODULE__{state: state, store: store}) do
    store.top(state)
  end

  @doc """
  Returns a stream of bottom leaderboard records.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.populate(board, [{-2, :id1}, {-3, :id2}])
      iex> Leaderboard.bottom(board) |> Enum.take(1)
      [{{-2, :id1}, :id1, {1, 2, 25.0, 0, 1}}]
  """
  @spec bottom(Leaderboard.t()) :: Enumerable.t()
  def bottom(%__MODULE__{state: state, store: store}) do
    store.bottom(state)
  end

  @doc """
  Returns the number of records in a leaderboard. This number is stored in the
  leaderboard, so this is an O(1) operation.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.populate(board, [{-2, :id1}, {-3, :id2}])
      iex> Leaderboard.count(board)
      2
  """
  @spec count(Leaderboard.t()) :: non_neg_integer
  def count(%__MODULE__{state: state, store: store}) do
    store.count(state)
  end

  @doc """
  Retrieves a single record from a leaderboard by id. Returns `nil` if record is
  not found.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.populate(board, [{-2, :id1}, {-3, :id2}])
      iex> Leaderboard.get(board, :id1)
      {{-2, :id1}, :id1, {1, 2, 25.0, 0, 1}}
      iex> Leaderboard.get(board, :missing_id)
      nil
  """
  @spec get(Leaderboard.t(), Entry.id()) :: Record.t()
  def get(%__MODULE__{state: state, store: store}, entry_id) do
    store.get(state, entry_id)
  end

  @doc """
  Retrieves a range of records from a leaderboard around the given id. Returns
  an empty list if the requested record is not found. If the range goes out of
  leaderboard bounds will stop at the top/bottom without error. If the given
  range is in reverse direction, returns entries in reverse direction as well.

  ## Examples

      iex> {:ok, board} = Leaderboard.create(name: :foo)
      iex> {:ok, board} = Leaderboard.populate(board, [
      ...>   {-4, :id1},
      ...>   {-3, :id2},
      ...>   {-2, :id3},
      ...>   {-1, :id4}
      ...> ])
      iex> Leaderboard.get(board, :id3, -1..0)
      [
        {{-3, :id2}, :id2, {1, 2, 62.5, 2, 1}},
        {{-2, :id3}, :id3, {2, 3, 37.5, 1, 1}}
      ]
      iex> Leaderboard.get(board, :id3, 0..-1)
      [
        {{-2, :id3}, :id3, {2, 3, 37.5, 1, 1}},
        {{-3, :id2}, :id2, {1, 2, 62.5, 2, 1}}
      ]
  """
  @spec get(Leaderboard.t(), Entry.id(), Range.t()) :: [Record.t()]
  def get(%__MODULE__{state: state, store: store}, entry_id, range) do
    store.get(state, entry_id, range)
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
