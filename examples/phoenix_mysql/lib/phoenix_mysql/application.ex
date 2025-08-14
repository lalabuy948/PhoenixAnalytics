defmodule PhoenixMysql.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhoenixMysqlWeb.Telemetry,
      PhoenixMysql.Repo,
      {DNSCluster, query: Application.get_env(:phoenix_mysql, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhoenixMysql.PubSub},
      # Start a worker by calling: PhoenixMysql.Worker.start_link(arg)
      # {PhoenixMysql.Worker, arg},
      # Start to serve requests, typically the last entry
      PhoenixMysqlWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixMysql.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhoenixMysqlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
