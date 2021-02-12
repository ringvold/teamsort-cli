defmodule Teamsort.Solver do
  @spec solve([Player]) :: [any()]
  def solve(players) do
    result = run_solver(players)
    IO.inspect(result)
    result_to_teams(players, result)
  end

  @spec run_solver([Player]) :: {:ok, any()} | {:error, any()}
  def run_solver(players) do
    MinizincSolver.solve_sync(
      Path.join(:code.priv_dir(:teamsort), "model.mzn"),
      %{
        playerRanks: Enum.map(players, & &1.rank),
        preference: Enum.map(players, & &1.team)
      },
      # TODO: make solver selectable
      solver: "org.minizinc.mip.coin-bc"
      # time_limit: 5000
    )
  end

  @spec result_to_teams(
          [Player],
          atom
          | %{
              :summary => atom | %{:last_solution => atom | map, optional(any) => any},
              optional(any) => any
            }
        ) :: list
  def result_to_teams(players, minizinc_response) do
    team_ints = minizinc_response.summary.last_solution.data["team"]

    Enum.zip(team_ints, players)
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.map(&players_to_team/1)
  end

  def players_to_team({number, numplay}) do
    players = Enum.map(numplay, fn {_num, p} -> p end)
    sum = Enum.map(players, & &1.rank) |> Enum.sum()
    %Team{name: "Team #{number}", players: Enum.sort_by(players, & &1.rank, :desc), score: sum}
  end

  def solve_raw do
    ranks = [12, 11, 9, 8, 16, 7, 7, 4, 9, 4, 5, 17, 11, 14, 8]

    MinizincSolver.solve_sync(
      Path.join(:code.priv_dir(:teamsort), "model.mzn"),
      %{
        playerRanks: ranks,
        preference: Enum.map(ranks, fn _ -> 0 end)
      },
      solver: "org.minizinc.mip.coin-bc"
      # time_limit: 1000
    )
  end
end
