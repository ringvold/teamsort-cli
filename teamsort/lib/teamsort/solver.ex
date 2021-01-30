defmodule Teamsort.Solver do
  def solve do
    ranks = [12, 11, 9, 8, 16, 7, 7, 4, 9, 6]

    MinizincSolver.solve_sync(
      Path.join(:code.priv_dir(:teamsort), "model.mzn"),
      %{
        playerRanks: ranks,
        preference: Enum.map(ranks, fn _ -> 0 end)
      }
    )
  end
end
