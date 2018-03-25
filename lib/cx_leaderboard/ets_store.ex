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

  def clear(name) do
    with :ok <- GenServer.stop(name),
         {:ok, _} <- GenServer.start_link(Writer, name, name: name) do
      {:ok, name}
    end
  end

  def populate(name, data) do
    process_multi_call(name, {:populate, data})
  end

  def async_populate(name, data) do
    :abcast = GenServer.abcast(name, {:populate, data})
    {:ok, name}
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
  defdelegate get(name, id, range), to: Ets
  defdelegate top(name), to: Ets
  defdelegate bottom(name), to: Ets
  defdelegate count(name), to: Ets

  ## Private

  defp process_multi_call(name, message) do
    name
    |> GenServer.multi_call(message)
    |> format_multi_call_reply(name)
  end

  defp format_multi_call_reply(replies = {nodes, bad_nodes}, name) do
    errors = collect_errors(replies)
    node_count = Enum.count(nodes) + Enum.count(bad_nodes)

    case {node_count, errors} do
      # no errors anywhere
      {_, []} ->
        {:ok, name}

      # only one node and one error, collapse to a simple error
      {1, [{_, reason}]} ->
        {:error, reason}

      # only one node but multiple errors, return all reasons in a list
      {1, errors} ->
        {:error, Enum.map(errors, fn {_, reason} -> reason end)}

      # multiple nodes and errors, return node-error pairs
      {_, errors} ->
        {:error, errors}
    end
  end

  defp collect_errors({nodes, bad_nodes}) do
    errors =
      nodes
      |> Enum.filter(&reply_has_errors?/1)
      |> Enum.map(fn {node, {:error, reason}} -> {node, reason} end)

    Enum.reduce(bad_nodes, errors, fn bad_node, errors ->
      [{bad_node, :bad_node} | errors]
    end)
  end

  defp reply_has_errors?({_, {:error, _}}), do: true
  defp reply_has_errors?(_), do: false
end
