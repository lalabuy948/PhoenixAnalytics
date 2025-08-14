defmodule PhoenixMysql.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_mysql,
    adapter: Ecto.Adapters.MyXQL
end
