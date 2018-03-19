defmodule CxLeaderboard.EtsStore.Writer do
  use GenServer
  alias CxLeaderboard.EtsStore.Ets

  def init(name) do
    Ets.init(name)
    {:ok, name}
  end

  def handle_call({:populate, data}, _from, name) do
    result = Ets.populate(name, data)
    # secs = time / 1000
    # IO.puts("[CxLeaderboard] #{name} indexed #{count} entries in #{secs}s")
    {:reply, result, name}
  end

  def handle_call({:add, entry}, _from, name) do
    result = Ets.add(name, entry)
    {:reply, result, name}
  end

  def handle_call({:remove, id}, _from, name) do
    result = Ets.remove(name, id)
    {:reply, result, name}
  end
end
