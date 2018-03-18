defmodule CxLeaderboard.Leaderboard do
  @enforce_keys [:id, :store]
  defstruct [:id, :store, :reply]
end
