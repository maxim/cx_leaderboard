defmodule CxLeaderboard.EtsStore.Writer do
  @moduledoc false

  use GenServer
  alias CxLeaderboard.EtsStore.Ets

  def init(name) do
    Ets.init(name)
    {:ok, name}
  end

  def handle_cast({:populate, data, indexer}, name) do
    Ets.populate(name, data, indexer)
    {:noreply, name}
  end

  def handle_call({:populate, data, indexer}, _from, name) do
    result = Ets.populate(name, data, indexer)
    {:reply, result, name}
  end

  def handle_call({:add, entry, indexer}, _from, name) do
    result = Ets.add(name, entry, indexer)
    {:reply, result, name}
  end

  def handle_call({:remove, id, indexer}, _from, name) do
    result = Ets.remove(name, id, indexer)
    {:reply, result, name}
  end

  def handle_call({:update, entry, indexer}, _from, name) do
    result = Ets.update(name, entry, indexer)
    {:reply, result, name}
  end

  def handle_call({:add_or_update, entry, indexer}, _from, name) do
    result = Ets.add_or_update(name, entry, indexer)
    {:reply, result, name}
  end
end
