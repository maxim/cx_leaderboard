defmodule CxLeaderboard.Storage do
  alias CxLeaderboard.{Leaderboard, Entry, Record}

  @doc """
  Create a leaderboard in your storage identified with the provided atom.
  """
  @callback create(keyword()) :: {:ok, Leaderboard.state()} | {:error, term}

  @doc """
  Clear all the data in your leaderboard state.
  """
  @callback clear(Leaderboard.state()) ::
              {:ok, Leaderboard.state()} | {:error, term}

  @doc """
  Replace all data in the leaderboard with the data in the provided stream.
  Block until completed.
  """
  @callback populate(Leaderboard.state(), Enumerable.t()) ::
              {:ok, Leaderboard.state()} | {:error, term}

  @doc """
  Replace all data in the leaderboard with the data in the provided stream.
  Return immediately, perform most of the work asynchronously.
  """
  @callback async_populate(Leaderboard.state(), Enumerable.t()) ::
              {:ok, term} | {:error, term}

  @doc """
  Add a single entry to the leaderboard. Return an error if the entry is already
  in the leaderboard. The operation should be blocking.
  """
  @callback add(Leaderboard.state(), Entry.t()) ::
              {:ok, Leaderboard.state()} | {:error, term}

  @doc """
  Remove a single entry from the leaderboard based on its id. Return an error if
  the id does not exist. The operation should be blocking.
  """
  @callback remove(Leaderboard.state(), Entry.id()) ::
              {:ok, Leaderboard.state()} | {:error, term}

  @doc """
  Update a single entry in the leaderboard. Return an error if the entry is not
  found in the leaderboard. The operation should be blocking.
  """
  @callback update(Leaderboard.state(), Entry.t()) ::
              {:ok, Leaderboard.state()} | {:error, term}

  @doc """
  Atomically insert an entry, or update it if its id already exists in the
  leaderboard.
  """
  @callback add_or_update(Leaderboard.state(), Entry.t()) ::
              {:ok, Leaderboard.state()} | {:error, term}

  @doc """
  Return a leaderboard record by its id. Return nil if not found.
  """
  @callback get(Leaderboard.state(), Entry.id()) :: Record.t() | nil

  @doc """
  Return a list of records around the given id. The list should go from top to
  bottom if the range is increasing, and from bottom to top if range decreasing.
  Zero always corresponds to where the id is positioned.

  For example:

    - A range -2..1 should return (from top to bottom) 2 records prior to the
      given id, the record at the given id, and 1 record after the given id.
    - A range 2..-2 should return (from bottom to top) 2 records after the given
      id, the record at the given id, and 2 records before the given id.
  """
  @callback range(Leaderboard.state(), Entry.id(), Range.t()) :: [Record.t()]

  @doc """
  Return a correctly ordered stream of top leaderboard records that can be
  accessed all the way to the end.
  """
  @callback top(Leaderboard.state()) :: Stream.t()

  @doc """
  Show the number of records in the leaderboard.
  """
  @callback count(Leaderboard.state()) :: non_neg_integer

  @optional_callbacks async_populate: 2
end
