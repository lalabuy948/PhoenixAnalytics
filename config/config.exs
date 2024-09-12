import Config

config :phoenix_analytics,
  app_domain: System.get_env("PHX_HOST") || "example.com",
  duckdb_path: System.get_env("DUCK_PATH") || "analytics.duckdb"
  # postgres_repo: "",
  # postgres_conn: "dbname=postgres user=postgres password=postgres host=127.0.0.1"

import_config "#{config_env()}.exs"
