defmodule PhoenixSqlite.Repo.Migrations.AddPhoenixAnalytics do
  use Ecto.Migration

  def up, do: PhoenixAnalytics.Migration.up()
  def down, do: PhoenixAnalytics.Migration.down()
end
