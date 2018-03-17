defmodule CxLeaderboard.Server do
  alias CxLeaderboard.EtsStore
  use GenServer

  def init(name) do
    EtsStore.init(name)
    {:ok, name}
  end

  def handle_call({:populate, data}, _from, name) do
    {:ok, {count, time}} = EtsStore.populate(name, data)
    # secs = time / 1000
    # IO.puts("[CxLeaderboard] #{name} indexed #{count} entries in #{secs}s")
    {:reply, {count, time}, name}
  end
end
