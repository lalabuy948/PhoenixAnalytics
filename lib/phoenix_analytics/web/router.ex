defmodule PhoenixAnalytics.Web.Router do
  @moduledoc """
  PhoenixAnalytics.Web.Router

  This module provides routing functionality for the Phoenix Analytics dashboard.

  It defines a macro `phoenix_analytics_dashboard` that sets up the necessary routes
  for the analytics dashboard, and a helper function `parse_options` to process
  the options passed to the macro.

  ## Macro: phoenix_analytics_dashboard/2

  Creates routes for the Phoenix Analytics dashboard.

  ### Parameters:
    - path: The base path for the dashboard routes.
    - opts: Optional keyword list of configuration options.

  ### Options:
    - :as - The name for the live session (default: :phoenix_analytics_dashboard)
    - :on_mount - Additional mount hooks to be executed (default: [])

  ### Usage:
  ```elixir
  phoenix_analytics_dashboard "/analytics"
  ```

  ## Function: parse_options/2

  Processes the options passed to the `phoenix_analytics_dashboard` macro.

  ### Parameters:
    - opts: The options keyword list.
    - path: The base path for the dashboard.

  ### Returns:
    A tuple containing the session name and session options.

  This function sets up the default on_mount hooks, including a custom hook to set
  the dashboard path, and allows for additional custom hooks to be added.
  It also configures the root layout for the dashboard.
  """
  defmacro phoenix_analytics_dashboard(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      scoped_path = Phoenix.Router.scoped_path(__MODULE__, path)
      {session_name, session_opts} = parse_options(opts, scoped_path)

      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        live_session session_name, session_opts do
          live("/", PhoenixAnalytics.Web.Live.Dashboard, :index, as: session_name)
        end
      end
    end
  end

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
