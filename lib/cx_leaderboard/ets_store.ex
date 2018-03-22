defmodule CxLeaderboard.EtsStore do
  @behaviour CxLeaderboard.Storage
  alias CxLeaderboard.EtsStore.{Ets, Writer}

  ## Writers

  def create(kwargs) do
    name = Keyword.get(kwargs, :name)

    case GenServer.start_link(Writer, name, name: name) do
      {:ok, _} -> {:ok, name}
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
    process_multi_call(name, {:populate, data})
  end

  def async_populate(name, data) do
    :abcast = GenServer.abcast(name, {:populate, data})
    {:ok, :abcast}
  end

  def add(name, entry) do
    process_multi_call(name, {:add, entry})
  end

  def remove(name, id) do
    process_multi_call(name, {:remove, id})
  end

  def update(name, entry) do
    process_multi_call(name, {:update, entry})
  end

  def add_or_update(name, entry) do
    process_multi_call(name, {:add_or_update, entry})
  end

  ## Readers

  defdelegate get(name, id), to: Ets
  defdelegate top(name), to: Ets
  defdelegate count(name), to: Ets

  ## Private

  defp process_multi_call(name, message) do
    name
    |> GenServer.multi_call(message)
    |> format_multi_call_reply()
  end

  defp format_multi_call_reply(replies = {nodes, []}) do
    if Enum.any?(nodes, fn
         {_, {:error, _}} -> true
         _ -> false
       end) do
      {:error, replies}
    else
      {:ok, replies}
    end
  end

  defp format_multi_call_reply(replies), do: {:error, replies}
end
