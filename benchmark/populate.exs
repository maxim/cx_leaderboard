samples =
  Stream.iterate({:rand.uniform(1_000_000), 1}, fn
    {_, id} -> {:rand.uniform(1_000_000), id + 1}
  end)

alias CxLeaderboard.Leaderboard

ets_board = Leaderboard.create!(name: :benchmark, store: CxLeaderboard.EtsStore)
term_board = Leaderboard.create!(store: CxLeaderboard.TermStore)
one_mil = samples |> Enum.take(1_000_000)

Benchee.run(%{
  "ets" => fn -> Leaderboard.populate(ets_board, one_mil) end,
  "term" => fn -> Leaderboard.populate(term_board, one_mil) end
})
