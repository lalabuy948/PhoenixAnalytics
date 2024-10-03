import Config

# config :phoenix_analytics,
#   duckdb_path: System.get_env("DUCKDB_PATH") || "analytics.duckdb",
#   app_domain: System.get_env("PHX_HOST") || "example.com",
#   postgres_conn: "dbname=postgres user=phoenix password=analytics host=localhost",
#   cache_ttl: System.get_env("CACHE_TTL") || 120 # seconds

import_config "#{config_env()}.exs"
