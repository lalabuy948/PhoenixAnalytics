defmodule DuckPostgres.Repo do
  use Ecto.Repo,
    otp_app: :duck_postgres,
    adapter: Ecto.Adapters.Postgres
end
