defmodule PhoenixAnalytics.Web do
  @moduledoc false

  @doc false
  def html do
    quote do
      import Phoenix.Controller, only: [get_csrf_token: 0]

      unquote(html_helpers())
    end
  end

  @doc false
  def live_view do
    quote do
      use Phoenix.LiveView, layout: {PhoenixAnalytics.Web.Layouts, :app}

      unquote(html_helpers())
    end
  end

  @doc false
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  @doc false
  def router do
    quote do
      import PhoenixAnalytics.Web.Router
    end
  end

  defp html_helpers do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import Phoenix.LiveView.Helpers
      import PhoenixAnalytics.Web.CoreComponents

      import LiveReact

      alias Phoenix.LiveView.JS
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
