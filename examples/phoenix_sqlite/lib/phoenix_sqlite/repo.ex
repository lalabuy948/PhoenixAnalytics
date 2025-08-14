defmodule PhoenixSqlite.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_sqlite,
    adapter: Ecto.Adapters.SQLite3
end
