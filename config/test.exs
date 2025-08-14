import Config

# Test configuration for Phoenix Analytics
# The library will automatically detect available database adapters
# No specific configuration needed for testing

config :phoenix_analytics, PhoenixAnalytics.SqliteRepo,
  database: Path.expand("../phoenix_analytics_dev.db", __DIR__),
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :phoenix_analytics,
  repo: PhoenixAnalytics.SqliteRepo,
  app_domain: "localhost",
  cache_ttl: 60
