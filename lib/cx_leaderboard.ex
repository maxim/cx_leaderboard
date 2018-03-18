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
  alias CxLeaderboard.Leaderboard

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

  # TODO:
  # Specify storage here
  def create(name) do
    reply = {:ok, _} = GenServer.start_link(Server, name, name: name)
    {:ok, %Leaderboard{id: name, reply: reply}}
  end

  def destroy(leaderboard = %Leaderboard{id: id}) do
    reply = GenServer.stop(id)
    Map.put(leaderboard, :reply, reply)
  end

  def populate(leaderboard = %Leaderboard{id: id}, data) do
    reply = GenServer.multi_call(id, {:populate, data})
    Map.put(leaderboard, :reply, reply)
  end

  def populate(leaderboard = %Leaderboard{id: id}, data, async: true) do
    reply = GenServer.abcast(id, {:populate, data})
    Map.put(leaderboard, :reply, reply)
  end

  # def add(name, score, entry) do
  # end

  ## Reader functions

  def top(%Leaderboard{id: id}) do
    EtsStore.top(id)
  end

  def count(%Leaderboard{id: id}) do
    EtsStore.count(id)
  end
end
