defmodule Teamsort.Player do
  @derive Jason.Encoder
  @enforce_keys [:name, :rank]
  defstruct [:name, :rank, :rank_name, team: 0]
end
