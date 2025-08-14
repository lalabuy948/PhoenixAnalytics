defmodule PhoenixPostgres.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_postgres,
    adapter: Ecto.Adapters.Postgres
end
