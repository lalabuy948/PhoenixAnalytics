defmodule DuckPostgresInMemoryWeb.Router do
  use DuckPostgresInMemoryWeb, :router
  use PhoenixAnalytics.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DuckPostgresInMemoryWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DuckPostgresInMemoryWeb do
    pipe_through :browser

    get "/", PageController, :home
    phoenix_analytics_dashboard "/analytics"
  end

  # Other scopes may use custom stacks.
  # scope "/api", DuckPostgresInMemoryWeb do
  #   pipe_through :api
  # end
end
