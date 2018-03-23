samples =
  Stream.iterate({:rand.uniform(1_000_000), 1}, fn
    {_, id} -> {:rand.uniform(1_000_000), id + 1}
  end)

alias CxLeaderboard.Leaderboard

one_mil = samples |> Enum.take(1_000_000)

ets_board =
  Leaderboard.create!(name: :benchmark, store: CxLeaderboard.EtsStore)
  |> Leaderboard.populate!(one_mil)

term_board =
  Leaderboard.create!(store: CxLeaderboard.TermStore)
  |> Leaderboard.populate!(one_mil)

Benchee.run(%{
  "ets" => fn -> Leaderboard.add(ets_board, {500_000, 2_000_000}) end,
  "term" => fn -> Leaderboard.add(term_board, {500_000, 2_000_000}) end
})
