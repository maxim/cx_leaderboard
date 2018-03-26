# CxLeaderboard

A featureful, efficient leaderboard based on ets store. Supports records of any shape.

```elixir
alias CxLeaderboard.Leaderboard

board =
  Leaderboard.create!(name: :global)
  |> Leaderboard.populate!([
    {-20, :id1},
    {-30, :id2}
  ])

records =
  board
  |> Leaderboard.top()
  |> Enum.take(2)

# Returned records (explained):
#   {{score, id}, payload, {index, rank, percentile}}
# [ {{-30,  :id2}, :id2,   {0,     {1,    99.0}}},
#   {{-20,  :id1}, :id1,   {1,     {2,    50.0}}} ]
```

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
