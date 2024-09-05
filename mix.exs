defmodule PhoenixAnalytics.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :phoenix_analytics,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/lalabuy948/PhoenixAnalytics",
      homepage_url: "https://github.com/lalabuy948/PhoenixAnalytics",
      name: "PhoenixAnalytics",
      docs: [
        main: "PhoenixAnalytics",
        formatters: ["html"],
        groups_for_modules: groups_for_modules(),
        api_reference: false,
        extras: ["README.md"],
        main: "readme"
      ]
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/lalabuy948/PhoenixAnalytics"
      },
      maintainers: [
        "lalabuy948"
      ],
      files: ~w(lib priv/static/assets LICENSE mix.exs README.md .formatter.exs)
    ]
  end

  def description do
    "Plug and play analytics for Phoenix applications. "
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PhoenixAnalytics.Application, []},
      extra_applications: [:logger, :telemetry]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:plug, "~> 1.16"},
      {:cachex, "~> 3.6"},
      {:gettext, "~> 0.20"},
      {:duckdbex, "~> 0.3"},
      {:telemetry, "~> 1.2"},
      {:live_react, "~> 0.1"},
      {:phoenix_live_view, "~> 1.0.0-rc.1 or ~> 1.0"},
      # --- dev deps ---
      {:ex_doc, "~> 0.33", only: :dev},
      {:esbuild, "~> 0.8", only: :dev, runtime: false},
      {:tailwind, "~> 0.1", only: :dev, runtime: false}
    ]
  end

  defp groups_for_modules do
    [
      Integrations: [
        PhoenixAnalytics.Plugs.RequestTracker
      ],
      Entities: [
        PhoenixAnalytics.Entities.RequestLog
      ],
      Dashboard: [
        PhoenixAnalytics.Web.Router
      ],
      Services: [
        PhoenixAnalytics.Services.Batcher,
        PhoenixAnalytics.Services.Cache,
        PhoenixAnalytics.Services.PubSub,
        PhoenixAnalytics.Services.Telemetry,
        PhoenixAnalytics.Services.Utility
      ],
      Repository: [
        PhoenixAnalytics.Repo
      ]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "cmd --cd assets npm install"
      ],
      "assets.build": [
        "tailwind phoenix_analytics",
        "esbuild phoenix_analytics"
      ],
      "assets.watch": [
        "tailwind phoenix_analytics --watch",
        "esbuild phoenix_analytics --watch"
      ],
      "assets.deploy": [
        "tailwind phoenix_analytics --minify",
        "esbuild phoenix_analytics --minify --metafile=meta.json"
      ]
    ]
  end
end
