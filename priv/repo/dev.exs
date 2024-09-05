#!/usr/bin/env elixir
Mix.install([
  {:phoenix_playground, "~> 0.1.5"},
  {:phoenix_analytics, path: "../phoenix_analytics", force: true}
])

IO.puts("DUCK_PATH: #{System.get_env("DUCK_PATH")}")
PhoenixAnalytics.Migration.up()

defmodule DevLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def render(assigns) do
    ~H"""
    <span><%= @count %></span>
    <button phx-click="inc">+</button>
    <button phx-click="dec">-</button>

    <style type="text/css">
      body { padding: 1em; }
    </style>
    """
  end

  def handle_event("inc", _params, socket) do
    {:noreply, assign(socket, count: socket.assigns.count + 1)}
  end

  def handle_event("dec", _params, socket) do
    {:noreply, assign(socket, count: socket.assigns.count - 1)}
  end
end

defmodule DevController do
  use Phoenix.Controller, formats: [:html]
  use Phoenix.Component
  plug :put_layout, false
  plug :put_view, __MODULE__

  def index(conn, params) do
    count =
      case Integer.parse(params["count"] || "") do
        {n, ""} -> n
        _ -> 0
      end

    render(conn, :index, count: count)
  end

  def index(assigns) do
    ~H"""
    <span><%= @count %></span>
    <button onclick={"window.location.href=\"/?count=#{@count + 1}\""}>+</button>
    <button onclick={"window.location.href=\"/?count=#{@count - 1}\""}>-</button>

    <style type="text/css">
      body { padding: 1em; }
    </style>
    """
  end
end

defmodule DevRouter do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  use PhoenixAnalytics.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_secure_browser_headers
    # plug PhoenixAnalytics.Plugs.RequestTracker
  end

  scope "/" do
    pipe_through :browser

    live_session :default do
      live "/", DevLive
    end
  end

  scope "/dev" do
    pipe_through :browser

    phoenix_analytics_dashboard("/analytics")
  end
end

PhoenixPlayground.start(
  plug: DevRouter,
  endpoint_options: [
    secret_key_base: "gpaTilt0aZo38EYNrPqIA8rNGhsuysCMe8GxMps6/HZQ3xnjtIiG0UyKIHBaI+FM"
  ],
  open_browser: false,
  child_specs: []
)
