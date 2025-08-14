defmodule PhoenixMysql.Repo.Migrations.AddPhoenixAnalyticsIndexes do
  use Ecto.Migration

  def change do
    PhoenixAnalytics.Migration.add_indexes()
  end
end
