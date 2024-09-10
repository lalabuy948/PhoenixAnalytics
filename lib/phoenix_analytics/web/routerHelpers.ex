defmodule PhoenixAnalytics.Web.RouterHelpers do
  def parse_options(opts, path) do
    custom_on_mount = Keyword.get(opts, :on_mount, [])

    on_mount =
      [{PhoenixAnalytics.Web.Hooks.SetAssigns, {:set_dashboard_path, path}}] ++ custom_on_mount

    session_name = Keyword.get(opts, :as, :phoenix_analytics_dashboard)

    session_opts = [
      on_mount: on_mount,
      root_layout: {PhoenixAnalytics.Web.Layouts, :root}
    ]

    {session_name, session_opts}
  end
end
