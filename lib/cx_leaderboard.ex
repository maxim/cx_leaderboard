defmodule CxLeaderboard do
  @moduledoc """
  Documentation for CxLeaderboard.

  TODO:
    - [DONE] Rewrite Index.build
    - [DONE] Allow add/remove entries (rebuild only index) but still leave
      populate() function for initial setup
    - [DONE] Decide how to handle invalid entries
    - [DONE] Move Server logic under EtsStore
    - [DONE] Formalize storage as a behaviour
    - [DONE] Implement update function
    - [DONE] Move data stream processing (and format_entry) out of storage
    - Add add_or_update for more efficient upsert
    - Implement scoping
    - Implement status fetching
    - Add benchmark
    - Figure out how to reuse this library at Crossfield
    - Docs
    - Typespecs
    - More tests
  """

  alias CxLeaderboard.{Leaderboard, Entry}

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

    case store.create(name) do
      :ok ->
        {:ok, %Leaderboard{id: name, store: store}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create!(name, kwargs \\ []) do
    {:ok, board} = create(name, kwargs)
    board
  end

  def destroy(lb = %Leaderboard{id: id, store: store}) do
    case store.destroy(id) do
      :ok ->
        {:ok, lb}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def destroy!(lb) do
    {:ok, _} = destroy(lb)
    lb
  end

  def populate(%Leaderboard{id: id, store: store}, data) do
    store.populate(id, build_data_stream(data))
  end

  def populate!(lb, data) do
    {:ok, _} = populate(lb, build_data_stream(data))
    lb
  end

  def async_populate(%Leaderboard{id: id, store: store}, data) do
    store.async_populate(id, build_data_stream(data))
  end

  def async_populate!(lb, data) do
    {:ok, _} = async_populate(lb, build_data_stream(data))
    lb
  end

  def add(%Leaderboard{id: id, store: store}, entry) do
    case Entry.format(entry) do
      error = {:error, _} -> error
      entry -> store.add(id, entry)
    end
  end

  def add!(lb, entry) do
    {:ok, _} = add(lb, entry)
    lb
  end

  def update(%Leaderboard{id: id, store: store}, entry) do
    case Entry.format(entry) do
      error = {:error, _} -> error
      entry -> store.update(id, entry)
    end
  end

  def update!(lb, entry) do
    {:ok, _} = update(lb, entry)
    lb
  end

  def remove(%Leaderboard{id: id, store: store}, entry_id) do
    store.remove(id, entry_id)
  end

  def remove!(lb, entry_id) do
    {:ok, _} = remove(lb, entry_id)
    lb
  end

  ## Reader functions

  def top(%Leaderboard{id: id, store: store}) do
    store.top(id)
  end

  def count(%Leaderboard{id: id, store: store}) do
    store.count(id)
  end

  ## Private

  defp build_data_stream(data) do
    data
    |> Stream.map(&Entry.format/1)
    |> Stream.reject(fn
      {:error, _} -> true
      _ -> false
    end)
  end
end
