defmodule Teamsort.Player do
  @derive Jason.Encoder
  @enforce_keys [:name, :rank]
  defstruct [:name, :rank, :rank_name, team: 0]

  def to_string(player) do
    Map.to_list(player)
    |> Enum.reduce("", fn {key, value}, acc ->
      if key == :__struct__ do
        acc
      else
        "#{acc},#{Atom.to_string(key)}, #{value}"
      end
    end)
  end
end
