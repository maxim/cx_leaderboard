defmodule CxLeaderboard.EtsStore.Writer do
  @moduledoc false

  use GenServer
  alias CxLeaderboard.EtsStore.Ets

  def init({name, lb = %{data: data, indexer: indexer}}) do
    Ets.init(name)
    Ets.populate(name, data, indexer)
    {:ok, {name, lb}}
  end

  def init(name) do
    Ets.init(name)
    {:ok, {name, nil}}
  end

  def handle_cast({:populate, data, indexer}, state = {name, _}) do
    Ets.populate(name, data, indexer)
    {:noreply, state}
  end

  def handle_call({:populate, data, indexer}, _from, state = {name, _}) do
    result = Ets.populate(name, data, indexer)
    {:reply, result, state}
  end

  def handle_call({:add, entry, indexer}, _from, state = {name, _}) do
    result = Ets.add(name, entry, indexer)
    {:reply, result, state}
  end

  def handle_call({:remove, id, indexer}, _from, state = {name, _}) do
    result = Ets.remove(name, id, indexer)
    {:reply, result, state}
  end

  def handle_call({:update, entry, indexer}, _from, state = {name, _}) do
    result = Ets.update(name, entry, indexer)
    {:reply, result, state}
  end

  def handle_call({:add_or_update, entry, indexer}, _from, state = {name, _}) do
    result = Ets.add_or_update(name, entry, indexer)
    {:reply, result, state}
  end

  def handle_call(:get_lb, _from, state = {_, lb}) do
    {:reply, lb, state}
  end
end
