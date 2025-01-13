defmodule DuckPostgresInMemory.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DuckPostgresInMemoryWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:duck_postgres_in_memory, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DuckPostgresInMemory.PubSub},
      # Start a worker by calling: DuckPostgresInMemory.Worker.start_link(arg)
      # {DuckPostgresInMemory.Worker, arg},
      # Start to serve requests, typically the last entry
      DuckPostgresInMemoryWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DuckPostgresInMemory.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DuckPostgresInMemoryWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
