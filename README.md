# CxLeaderboard

A featureful, fast leaderboard based on ets store. Can carry payloads, calculate custom stats, provide nearby entries around any entry, and do many other fun things.

```elixir
alias CxLeaderboard.Leaderboard

board =
  Leaderboard.create!(name: :global_lb)
  |> Leaderboard.populate!([
    {{-23, :id1}, :user1},
    {{-65, :id2}, :user2},
    {{-24, :id3}, :user3},
    {{-23, :id4}, :user4},
    {{-34, :id5}, :user5}
  ])

records =
  board
  |> Leaderboard.top()
  |> Enum.to_list()

# Returned records (explained):
#   {{score, id}, payload, {index, {rank, percentile}}}
# [ {{-65, :id2}, :user2,  {0,     {1,    99.0}}},
#   {{-65, :id3}, :user3,  {1,     {1,    99.0}}},
#   {{-34, :id5}, :user5,  {2,     {3,    59.8}}},
#   {{-23, :id1}, :user1,  {3,     {4,    40.2}}},
#   {{-23, :id4}, :user4,  {4,     {4,    40.2}}} ]
```

It's advised to give Leaderboard.populate/2 function a stream rather than a list of data. For example: it could be a stream that takes entries from paginated database queries.

## Features

* Ranks and percentiles
* Concurrent reads, sequential writes
* Stream API access to records from top and bottom
* O(1) querying of any record by id
* Adding, updating, removing, upserting of individual entries
* Fetching a range of records around a given id (contextual leaderboard)
* Pluggable data stores: `EtsStore` for big boards, `TermStore` for dynamic mini boards
* Support for custom ranking and other stat functions
* Atomic full repopulation in O(2n log n) time
* Multi-node support

## Installation

The package can be installed by adding `cx_leaderboard` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cx_leaderboard, "~> 0.1.0"}
  ]
end
```

## Fetching ranges

If you want to get a record and its context (nearby records), you can use a range.

```elixir
Leaderboard.get(board, :id3, -1..1)
# [
#   {{-34, :id5}, :user5, {1, {2, 79.4}}},
#   {{-24, :id3}, :user3, {2, {3, 59.8}}},
#   {{-23, :id1}, :user1, {3, {4, 40.2}}}
# ]
```

## Different ranking flavors

To use different ranking you can just create your own indexer. Here's an example of the above leaderboard only in this case we want sequential ranks.

```elixir
alias CxLeaderboard.{Leaderboard, Indexer}

my_indexer = %Indexer{on_rank:
  &CxLeaderboard.Indexer.Stats.sequential_rank_1_99_less_or_equal_percentile/1}

board =
  Leaderboard.create!(name: :global_lb, indexer: my_indexer)
  |> Leaderboard.populate!([
    {{-23, :id1}, :user1},
    {{-65, :id2}, :user2},
    {{-65, :id3}, :user3},
    {{-23, :id4}, :user4},
    {{-34, :id5}, :user5}
  ])

records =
  board
  |> Leaderboard.top()
  |> Enum.to_list()

# Returned records (explained):
# [ {{-65, :id2}, :user2, {0, {1, 99.0}}},
#   {{-65, :id3}, :user3, {1, {1, 99.0}}},
#   {{-34, :id5}, :user5, {2, {2, 59.8}}},
#   {{-23, :id1}, :user1, {3, {3, 40.2}}},
#   {{-23, :id4}, :user4, {4, {3, 40.2}}} ]
```

See docs for `CxLeaderboard.Indexer.Stats` for various functions you can plug into the indexer, or write your own.

## Mini-leaderboards

Sometimes all you need is to render a quick one-off leaderboard with just a few entries in it. For this you don't have to run a persistent ets, instead you can use `TermStore`.

```elixir
miniboard =
  Leaderboard.create!(store: CxLeaderboard.TermStore)
  |> Leaderboard.populate!(
    [
      {23, 1},
      {65, 2},
      {24, 3},
      {23, 4},
      {34, 5}
    ]
  )

miniboard
|> Leaderboard.top()
|> Enum.take(3)
# [
#   {{23, 1}, 1, {0, {1, 99.0}}},
#   {{23, 4}, 4, {1, {1, 99.0}}},
#   {{24, 3}, 3, {2, {3, 59.8}}}
# ]
```

This would produce a complete full-featured leaderboard that's entirely stored in the `miniboard` variable. Here's what the struct actually looks like:

```elixir
%CxLeaderboard.Leaderboard{
  indexer: %CxLeaderboard.Indexer{
    on_entry: &CxLeaderboard.Indexer.Stats.global_index/1,
    on_rank: &CxLeaderboard.Indexer.Stats.offset_rank_1_99_less_or_equal_percentile/1
  },
  state: %{
    count: 5,
    index: %{
      id1: {:id1, {-23, :id1}, {3, {4, 40.2}}},
      id2: {:id2, {-65, :id2}, {0, {1, 99.0}}},
      id3: {:id3, {-24, :id3}, {2, {3, 59.8}}},
      id4: {:id4, {-23, :id4}, {4, {4, 40.2}}},
      id5: {:id5, {-34, :id5}, {1, {2, 79.4}}}
    },
    table: [
      {{-65, :id2}, :user2},
      {{-34, :id5}, :user5},
      {{-24, :id3}, :user3},
      {{-23, :id1}, :user1},
      {{-23, :id4}, :user4}
    ]
  },
  store: CxLeaderboard.TermStore
}
```

From this you can gather some inner workings of the leaderboard. It's based on 2 tables, one keyed by id, and the other keyed and sorted by the score. The indexer defines the functions used to build the index table.

## Benchmark

These benchmarks use 1 million randomly generated records, however, the same set of records is used for both ets and term leaderboard within each benchmark.

```
Operating System: macOS
CPU Information: Intel(R) Core(TM) i7-6920HQ CPU @ 2.90GHz
Number of Available Cores: 8
Available memory: 16 GB
Elixir 1.6.2
Erlang 20.2.4
Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
parallel: 1
```

### Populating the leaderboard with 1mil entries

Script: [benchmark/populate.exs](benchmark/populate.exs)

```
Name           ips        average  deviation         median         99th %
ets           0.21         4.76 s     ±0.95%         4.76 s         4.81 s
term         0.169         5.91 s     ±0.00%         5.91 s         5.91 s

Comparison:
ets           0.21
term         0.169 - 1.24x slower
```

Summary:

  - It takes 5.14s to populate ets leaderboard with 1 million random scores.
  - It takes 6.41s to populate term leaderboard with 1 million random scores.

The leaderboard is fully sorted and indexed at the end.

### Adding an entry to 1mil leaderboard

Script: [benchmark/add_entry.exs](benchmark/add_entry.exs)

```
Name           ips        average  deviation         median         99th %
ets       148.95 K      0.00001 s    ±88.34%      0.00001 s      0.00002 s
term     0.00034 K         2.92 s     ±0.56%         2.92 s         2.94 s

Comparison:
ets       148.95 K
term     0.00034 K - 435227.97x slower
```

As you can see, you should not create a term leaderboard with a million entries, and especially not add more to it, it's designed for small leaderboards.

### Getting a -10..10 range from 1mil leaderboard

Script: [benchmark/range.exs](benchmark/range.exs)

```
Name           ips        average  deviation         median         99th %
ets        17.84 K      0.0560 ms    ±20.66%      0.0530 ms       0.101 ms
term     0.00290 K      345.13 ms     ±3.83%      345.04 ms      374.28 ms

Comparison:
ets        17.84 K
term     0.00290 K - 6158.09x slower
```

Another example of how the term leaderboard is not intended for big number of entries.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/cx_leaderboard](https://hexdocs.pm/cx_leaderboard).
