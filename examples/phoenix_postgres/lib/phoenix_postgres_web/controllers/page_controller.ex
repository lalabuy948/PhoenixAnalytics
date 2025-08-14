defmodule PhoenixPostgresWeb.PageController do
  use PhoenixPostgresWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
