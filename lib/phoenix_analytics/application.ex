defmodule PhoenixAnalytics.Application do
  @moduledoc false
  alias PhoenixAnalytics.Services.Utility

  use Application

  @cache_name PhoenixAnalytics.Services.Cache.name()
  @pubsub_name PhoenixAnalytics.Services.PubSub.name()

  @doc false
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: @pubsub_name},
      {Cachex, name: @cache_name},
      PhoenixAnalytics.Repo,
      PhoenixAnalytics.Services.Batcher
    ]

    run_migrations()

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  defp run_migrations do
    if Utility.mode() == :duck_only do
      PhoenixAnalytics.Migration.duck_up()
    end

    if Utility.mode() == :duck_postgres do
      PhoenixAnalytics.Migration.enable_postgres_ext()
    end
  end
end
