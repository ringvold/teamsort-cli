defmodule Teamsort.PlayerParser do
  import NimbleParsec

  alias Teamsort.Player

  player =
    utf8_string([{:not, 44}, {:not, 9}], min: 1)
    |> ignore(choice([string(","), string("\t")]))
    |> integer(min: 1)
    |> ignore(string("\n") |> repeat() |> optional())
    |> reduce({:construct_player, []})

  with_rankname =
    utf8_string([{:not, 44}, {:not, 9}], min: 1)
    |> ignore(choice([string(","), string("\t")]))
    |> utf8_string([{:not, 44}, {:not, 9}], min: 1)
    |> ignore(choice([string(","), string("\t")]))
    |> integer(min: 1)
    |> ignore(string("\n") |> repeat() |> optional())
    |> reduce({:construct_player, []})

  with_rankname_and_team =
    utf8_string([{:not, 44}, {:not, 9}], min: 1)
    |> ignore(choice([string(","), string("\t")]))
    |> utf8_string([{:not, 44}, {:not, 9}], min: 1)
    |> ignore(choice([string(","), string("\t")]))
    |> integer(min: 1)
    |> ignore(choice([string(","), string("\t")]))
    |> integer(min: 1)
    |> ignore(string("\n") |> repeat() |> optional())
    |> reduce({:construct_player, []})

  defparsec(
    :parse,
    choice([
      with_rankname_and_team,
      player,
      with_rankname
    ])
    |> repeat()
  )

  defp construct_player(args) do
    case args do
      [name, rank_name, team, rank] ->
        %Player{name: name, rank: rank, rank_name: rank_name, team: team}

      [name, rank_name, rank] ->
        %Player{name: name, rank: rank, rank_name: rank_name}

      [name, rank] ->
        %Player{name: name, rank: rank}
    end
  end
end
