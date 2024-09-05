defmodule PhoenixAnalytics.Web.Layouts do
  @moduledoc false

  use PhoenixAnalytics.Web, :html

  @css :code.priv_dir(:phoenix_analytics) |> Path.join("static/assets/app.css") |> File.read!()
  @js :code.priv_dir(:phoenix_analytics) |> Path.join("static/assets/app.js") |> File.read!()

  def get_content(:css), do: @css
  def get_content(:js), do: @js

  embed_templates("layouts/*")
end
