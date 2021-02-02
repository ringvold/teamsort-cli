defmodule Teamsort.Solver do
  def solve do
    ranks = [12, 11, 9, 8, 16, 7, 7, 4, 9, 4, 5, 17, 11, 14, 8]

    MinizincSolver.solve_sync(
      Path.join(:code.priv_dir(:teamsort), "model.mzn"),
      # Path.join(:code.priv_dir(:teamsort), "data.dzn"),
      %{
        playerRanks: ranks,
        preference: Enum.map(ranks, fn _ -> 0 end)
      },
      solver: "org.minizinc.mip.coin-bc",
      time_limit: 1000
    )
  end
end
