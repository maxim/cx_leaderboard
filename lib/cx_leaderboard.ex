defmodule CxLeaderboard do
  @moduledoc """
  Documentation for CxLeaderboard.

  TODO:
    - [DONE] Rewrite Index.build
    - Allow add/remove entries (rebuild only index) but still leave
      populate() function for initial setup
    - Decide how to handle invalid entries
    - Move Server logic under EtsStore
    - Figure out how to reuse this library at Crossfield
    - Docs
    - Typespecs
    - More tests
  """

  alias CxLeaderboard.Server
  alias CxLeaderboard.EtsStore

  @doc """
  Hello world.

  ## Examples

      iex> CxLeaderboard.hello
      :world

  """
  def hello do
    :world
  end

  ## Writer functions

  def create(name) do
    {:ok, _} = GenServer.start_link(Server, name, name: name)
    {:ok, name}
  end

  def destroy(name) do
    GenServer.stop(name)
  end

  # TODO: Rethink what is being returned here (name allows pipelines in tests)
  def populate(name, data) do
    GenServer.multi_call(name, {:populate, data})
    name
  end

  def populate(name, data, async: true) do
    GenServer.abcast(name, {:populate, data})
  end

  # def add(name, score, entry) do
  # end

  ## Reader functions

  def top(name) do
    EtsStore.top(name)
  end

  def count(name) do
    EtsStore.count(name)
  end
end
