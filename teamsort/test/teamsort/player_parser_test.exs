defmodule Teamsort.PlayerParserTest do
  use ExUnit.Case
  doctest Teamsort.PlayerParser

  alias Teamsort.PlayerParser
  alias Teamsort.Player

  defp parse(input), do: PlayerParser.parse(input) |> unwrap
  defp unwrap({:ok, acc, "", _, _, _}), do: acc
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse " <> rest}
  defp unwrap({:error, reason, _rest, _, _, _}), do: {:error, reason}

  test "parses one line comma separated" do
    assert parse("Player,10") == [%Player{name: "Player", rank: 10}]
  end

  test "parses one line tab separated" do
    assert parse("Player\t10") == [%Player{name: "Player", rank: 10}]
  end

  test "parses two lines tab and comma separated" do
    assert parse("Player\t10\nPlayer2,11") == [
             %Player{name: "Player", rank: 10},
             %Player{name: "Player2", rank: 11}
           ]
  end

  test "parses rank name" do
    assert parse("Player\t10\nPlayer2\tmg2\t12") == [
             %Player{name: "Player", rank: 10},
             %Player{name: "Player2", rank: 12, rank_name: "mg2"}
           ]
  end

  test "parses rank name and team pref" do
    assert parse("""
           Player\t10
           Player1\tmg2\t2\t10
           Player2\tmg2\t12
           Player3\tgn4\t1\t9\n\n
           Player\t10

           """) == [
             %Player{name: "Player", rank: 10},
             %Player{name: "Player1", rank_name: "mg2", team: 2, rank: 10},
             %Player{name: "Player2", rank: 12, rank_name: "mg2"},
             %Player{name: "Player3", rank: 9, rank_name: "gn4", team: 1},
             %Player{name: "Player", rank: 10}
           ]
  end
end
