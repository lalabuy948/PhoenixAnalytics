defmodule DuckPostgres.Repo.Migrations.AddRequestsTable do
  use Ecto.Migration

  def up, do: PhoenixAnalytics.Migration.up()
  def down, do: PhoenixAnalytics.Migration.down()
end
