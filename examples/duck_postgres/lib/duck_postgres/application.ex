defmodule DuckPostgres.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DuckPostgresWeb.Telemetry,
      DuckPostgres.Repo,
      {DNSCluster, query: Application.get_env(:duck_postgres, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DuckPostgres.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: DuckPostgres.Finch},
      # Start a worker by calling: DuckPostgres.Worker.start_link(arg)
      # {DuckPostgres.Worker, arg},
      # Start to serve requests, typically the last entry
      DuckPostgresWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DuckPostgres.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DuckPostgresWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
