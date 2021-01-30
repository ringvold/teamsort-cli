defmodule Teamsort.Repo do
  use Ecto.Repo,
    otp_app: :teamsort,
    adapter: Ecto.Adapters.Postgres
end
