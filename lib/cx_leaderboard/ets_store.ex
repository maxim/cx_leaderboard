defmodule CxLeaderboard.EtsStore do
  alias CxLeaderboard.EtsStore.{Ets, Writer}

  ## Writers

  def create(name) do
    case GenServer.start_link(Writer, name, name: name) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  def destroy(name) do
    case GenServer.stop(name) do
      :ok -> :ok
      error -> error
    end
  end

  def populate(name, data) do
    name
    |> GenServer.multi_call({:populate, data})
    |> format_multi_call_reply()
  end

  def async_populate(name, data) do
    :abcast = GenServer.abcast(name, {:populate, data})
    {:ok, :abcast}
  end

  def add(name, entry) do
    name
    |> GenServer.multi_call({:add, entry})
    |> format_multi_call_reply()
  end

  def remove(name, id) do
    name
    |> GenServer.multi_call({:remove, id})
    |> format_multi_call_reply()
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

  defp format_multi_call_reply(replies = {_, []}), do: {:ok, replies}
  defp format_multi_call_reply(replies), do: {:error, replies}
end
