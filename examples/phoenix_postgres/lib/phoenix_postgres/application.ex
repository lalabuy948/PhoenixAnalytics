defmodule PhoenixPostgres.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhoenixPostgresWeb.Telemetry,
      PhoenixPostgres.Repo,
      {DNSCluster, query: Application.get_env(:phoenix_postgres, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhoenixPostgres.PubSub},
      # Start a worker by calling: PhoenixPostgres.Worker.start_link(arg)
      # {PhoenixPostgres.Worker, arg},
      # Start to serve requests, typically the last entry
      PhoenixPostgresWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixPostgres.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhoenixPostgresWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
