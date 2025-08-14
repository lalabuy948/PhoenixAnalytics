defmodule PhoenixMysqlWeb.PageController do
  use PhoenixMysqlWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
