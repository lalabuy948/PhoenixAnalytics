defmodule DuckOnly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DuckOnlyWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:duck_only, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DuckOnly.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: DuckOnly.Finch},
      # Start a worker by calling: DuckOnly.Worker.start_link(arg)
      # {DuckOnly.Worker, arg},
      # Start to serve requests, typically the last entry
      DuckOnlyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DuckOnly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DuckOnlyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
