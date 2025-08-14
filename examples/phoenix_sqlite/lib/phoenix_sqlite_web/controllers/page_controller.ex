defmodule PhoenixSqliteWeb.PageController do
  use PhoenixSqliteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
