defmodule CxLeaderboard.EtsStore do
  alias CxLeaderboard.EtsStore.{Ets, Writer}

  ## Writers

  def create(name) do
    response = {:ok, _} = GenServer.start_link(Writer, name, name: name)
    response
  end

  def destroy(name) do
    GenServer.stop(name)
  end

  def populate(name, data) do
    GenServer.multi_call(name, {:populate, data})
  end

  def async_populate(name, data) do
    GenServer.abcast(name, {:populate, data})
  end

  ## Readers

  def get(name, id) do
    Ets.get(name, id)
  end

  def top(name) do
    Ets.top(name)
  end

  def count(name) do
    Ets.count(name)
  end
end
