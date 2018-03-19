defmodule CxLeaderboard.Storage do
  alias CxLeaderboard.Leaderboard

  @doc """
  Create a leaderboard in your storage identified with the provided atom.
  """
  @callback create(Leaderboard.id()) :: :ok | {:error, term}

  @doc """
  Destroy all the data in your storage for the given leaderboard id.
  """
  @callback destroy(Leaderboard.id()) :: :ok | {:error, term}

  @doc """
  Replace all data in the leaderboard at a given id with the provided data.

  Notes:

    - It's advisable to skip any invalid entries silently
    - Block until completed
  """
  @callback populate(Leaderboard.id(), Enumerable.t()) ::
              {:ok, term} | {:error, term}

  @doc """
  Replace all data in the leaderboard at a given id with the provided data.

  Notes:

    - It's advisable to skip any invalid entries silently
    - Return immediately, perform most of the work asynchronously
  """
  @callback async_populate(Leaderboard.id(), Enumerable.t()) ::
              {:ok, term} | {:error, term}

  @doc """
  Add a single entry to the leaderboard. Return an error if an entry is invalid.
  The operation should be blocking.
  """
  @callback add(Leaderboard.id(), Leaderboard.entry()) ::
              {:ok, term} | {:error, term}

  @doc """
  Remove a single entry from the leaderboard based on its id. Return an error if
  the id does not exist. The operation should be blocking.
  """
  @callback remove(Leaderboard.id(), Leaderboard.entry_id()) ::
              {:ok, term} | {:error, term}

  @doc """
  Return a leaderboard record by its id. Return nil if not found.
  """
  @callback get(Leaderboard.id(), Leaderboard.entry_id()) ::
              Leaderboard.record() | nil

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
