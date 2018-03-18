defmodule CxLeaderboard do
  @moduledoc """
  Documentation for CxLeaderboard.

  TODO:
    - [DONE] Rewrite Index.build
    - Allow add/remove entries (rebuild only index) but still leave
      populate() function for initial setup
    - Decide how to handle invalid entries
    - [DONE] Move Server logic under EtsStore
    - Figure out how to reuse this library at Crossfield
    - Docs
    - Typespecs
    - More tests
  """

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

  def create(name, kwargs \\ []) do
    store = Keyword.get(kwargs, :store, CxLeaderboard.EtsStore)
    reply = store.create(name)
    %Leaderboard{id: name, store: store, reply: reply}
  end

  def destroy(lb = %Leaderboard{id: id, store: store}) do
    reply = store.destroy(id)
    Map.put(lb, :reply, reply)
  end

  def populate(lb = %Leaderboard{id: id, store: store}, data) do
    reply = store.populate(id, data)
    Map.put(lb, :reply, reply)
  end

  def async_populate(lb = %Leaderboard{id: id, store: store}, data) do
    reply = store.async_populate(id, data)
    Map.put(lb, :reply, reply)
  end

  # def add(name, score, entry) do
  # end

  ## Reader functions

  def top(%Leaderboard{id: id, store: store}) do
    store.top(id)
  end

  def count(%Leaderboard{id: id, store: store}) do
    store.count(id)
  end
end
