import Config

config :phoenix_analytics,
  app_domain: System.get_env("PHX_HOST") || "example.com",
  duckdb_path: System.get_env("DUCK_PATH") || "analytics.duckdb"

# postgres_conn: "dbname=postgres user=phoenix password=analytics host=localhost"

import_config "#{config_env()}.exs"
