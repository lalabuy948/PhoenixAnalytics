defmodule PhoenixAnalytics.Web.Layouts do
  @moduledoc """
  Provides layout components for the Phoenix Analytics dashboard.

  When using a custom `:root_layout`, include the analytics assets in your
  root layout's `<head>` by calling `PhoenixAnalytics.Web.Layouts.analytics_head/1`:

      <PhoenixAnalytics.Web.Layouts.analytics_head />
  """

  use PhoenixAnalytics.Web, :html

  @css :code.priv_dir(:phoenix_analytics) |> Path.join("static/assets/app.css") |> File.read!()
  @js :code.priv_dir(:phoenix_analytics) |> Path.join("static/assets/app.js") |> File.read!()

  def get_content(:css), do: @css
  def get_content(:js), do: @js

  @doc """
  Renders the analytics CSS and JS assets as inline `<style>` and `<script>` tags.

  Include this in the `<head>` of your custom root layout when using the
  `:root_layout` option on `phoenix_analytics_dashboard/2`.

  ## Example

      <head>
        <!-- your existing assets -->
        <PhoenixAnalytics.Web.Layouts.analytics_head />
      </head>
  """
  def analytics_head(assigns) do
    assigns = assign(assigns, :css, @css)
    assigns = assign(assigns, :js, @js)

    ~H"""
    <style>
      <%= raw(@css) %>
    </style>
    <script>
      <%= raw(@js) %>
    </script>
    """
  end

  embed_templates("layouts/*")
end
