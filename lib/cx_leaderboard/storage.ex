defmodule CxLeaderboard.Storage do
  alias CxLeaderboard.{Leaderboard, Entry, Record}

  @doc """
  Create a leaderboard in your storage identified with the provided atom.
  """
  @callback create(Leaderboard.id()) :: {:ok, Leaderboard.t()} | {:error, term}

  @doc """
  Destroy all the data in your storage for the given leaderboard id.
  """
  @callback destroy(Leaderboard.id()) :: :ok | {:error, term}

  @doc """
  Replace all data in the leaderboard with the data in the provided stream.
  Block until completed.
  """
  @callback populate(Leaderboard.id(), Enumerable.t()) ::
              {:ok, term} | {:error, term}

  @doc """
  Replace all data in the leaderboard with the data in the provided stream.
  Return immediately, perform most of the work asynchronously.
  """
  @callback async_populate(Leaderboard.id(), Enumerable.t()) ::
              {:ok, term} | {:error, term}

  @doc """
  Add a single entry to the leaderboard. Return an error if the entry is already
  in the leaderboard. The operation should be blocking.
  """
  @callback add(Leaderboard.id(), Entry.t()) :: {:ok, term} | {:error, term}

  @doc """
  Remove a single entry from the leaderboard based on its id. Return an error if
  the id does not exist. The operation should be blocking.
  """
  @callback remove(Leaderboard.id(), Entry.id()) ::
              {:ok, term} | {:error, term}

  @doc """
  Update a single entry in the leaderboard. Return an error if the entry is not
  found in the leaderboard. The operation should be blocking.
  """
  @callback update(Leaderboard.id(), Entry.t()) :: {:ok, term} | {:error, term}

  @doc """
  Atomically insert an entry, or update it if its id already exists in the
  leaderboard.
  """
  @callback add_or_update(Leaderboard.id(), Entry.t()) ::
              {:ok, term} | {:error, term}

  @doc """
  Return a leaderboard record by its id. Return nil if not found.
  """
  @callback get(Leaderboard.id(), Entry.id()) :: Record.t() | nil

  @doc """
  Return a correctly ordered stream of top leaderboard records that can be
  accessed all the way to the end.
  """
  @callback top(Leaderboard.id()) :: Stream.t()

  @doc """
  Show the number of records in the leaderboard.
  """
  @callback count(Leaderboard.id()) :: non_neg_integer
end
