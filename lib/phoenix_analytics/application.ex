defmodule PhoenixAnalytics.Application do
  @moduledoc false

  use Application

  @cache_name PhoenixAnalytics.Services.Cache.name()
  @pubsub_name PhoenixAnalytics.Services.PubSub.name()

  @doc false
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: @pubsub_name},
      {Cachex, name: @cache_name},
      PhoenixAnalytics.Services.Batcher
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
