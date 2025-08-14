import Config

# Example configuration for Phoenix Analytics in development
# Replace MyApp.Repo with your actual repository module

# Basic configuration (using your existing repo)
config :phoenix_analytics,
  repo: MyApp.Repo,
  app_domain: "localhost",
  cache_ttl: 60

config :esbuild, :version, "0.17.11"
config :tailwind, :version, "3.4.13"

# Configure esbuild (the version is required)
config :esbuild,
  phoenix_analytics: [
    args:
      ~w(js/app.js --bundle --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  phoenix_analytics: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
