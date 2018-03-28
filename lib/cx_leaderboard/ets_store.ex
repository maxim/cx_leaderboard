defmodule CxLeaderboard.EtsStore do
  @moduledoc """
  Use this storage engine to get efficient leaderboards powered by ets. Supports
  client/server mode via `CxLeaderboard.Leaderboard.start_link/1` and
  `CxLeaderboard.Leaderboard.async_populate/2`. This is the default storage
  engine.
  """

  @behaviour CxLeaderboard.Storage
  alias CxLeaderboard.EtsStore.{Ets, Writer}

  ## Writers

  @doc false
  def create(kwargs) do
    name = Keyword.get(kwargs, :name)

    case GenServer.start_link(Writer, name, name: name) do
      {:ok, _} -> {:ok, name}
      error -> error
    end
  end

  @doc false
  def clear(name) do
    with :ok <- GenServer.stop(name),
         {:ok, _} <- GenServer.start_link(Writer, name, name: name) do
      {:ok, name}
    end
  end

  @doc false
  def populate(name, data, indexer) do
    process_multi_call(name, {:populate, data, indexer})
  end

  @doc false
  def async_populate(name, data, indexer) do
    :abcast = GenServer.abcast(name, {:populate, data, indexer})
    {:ok, name}
  end

  @doc false
  def add(name, entry, indexer) do
    process_multi_call(name, {:add, entry, indexer})
  end

  @doc false
  def remove(name, id, indexer) do
    process_multi_call(name, {:remove, id, indexer})
  end

  @doc false
  def update(name, entry, indexer) do
    process_multi_call(name, {:update, entry, indexer})
  end

  @doc false
  def add_or_update(name, entry, indexer) do
    process_multi_call(name, {:add_or_update, entry, indexer})
  end

  @doc false
  def start_link(name) do
    GenServer.start_link(Writer, name, name: name)
  end

  ## Readers

  @doc false
  defdelegate get(name, id), to: Ets

  @doc false
  defdelegate get(name, id, range), to: Ets

  @doc false
  defdelegate top(name), to: Ets

  @doc false
  defdelegate bottom(name), to: Ets

  @doc false
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
