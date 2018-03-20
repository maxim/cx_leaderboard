defmodule CxLeaderboard.Leaderboard do
  @enforce_keys [:id, :store]
  defstruct [:id, :store]

  @typedoc """
  Identifies a specific leaderboard among many.
  """
  @type id :: atom
end
