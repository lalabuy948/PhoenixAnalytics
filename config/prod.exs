import Config

# Phoenix Analytics production configuration
config :phoenix_analytics,
  app_domain: System.get_env("PHX_HOST") || "example.com",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "20"),
  cache_ttl: String.to_integer(System.get_env("CACHE_TTL") || "300")
