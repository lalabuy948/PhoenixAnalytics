import Config

config :esbuild, :version, "0.17.11"
config :tailwind, :version, "3.2.7"

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
