# 📊 Phoenix Analytics

<p align="center">
  <a title="GitHub CI" href="https://github.com/lalabuy948/PhoenixAnalytics/actions"><img src="https://github.com/lalabuy948/PhoenixAnalytics/actions/workflows/tests.yml/badge.svg" alt="GitHub CI" /></a>
  <a title="Latest release" href="https://hex.pm/packages/phoenix_analytics"><img src="https://img.shields.io/hexpm/v/phoenix_analytics.svg" alt="Latest release" /></a>
  <a title="View documentation" href="https://hexdocs.pm/phoenix_analytics"><img src="https://img.shields.io/badge/hex.pm-docs-blue.svg" alt="View documentation" /></a>
</p>

![](https://raw.githubusercontent.com/lalabuy948/PhoenixAnalytics/master/github/hero.png)

![](https://raw.githubusercontent.com/lalabuy948/PhoenixAnalytics/master/github/screenshot.png)

Phoenix Analytics is embedded plug and play tool designed for Phoenix applications. It provides a simple and efficient way to track and analyze user behavior and application performance without impacting your main application's performance and database.

Key features:
- ⚡️ Lightweight and fast analytics tracking
- ⛓️‍💥 Separate storage using DuckDB to avoid affecting your main database
- 🔌 Easy integration with Phoenix applications
- 📊 Minimalistic dashboard for data visualization

> The decision to use [DuckDB](https://duckdb.org) as the storage was made to ensure that the analytics data collection process does not interfere with or degrade the performance of your application's primary transactional database. This separation allows for efficient data storage and querying specifically optimized for analytics purposes, while keeping your main database focused on serving your application's core functionality.


https://github.com/user-attachments/assets/66ee00d4-3928-46ec-bfca-c03e2569bc0a


## Installation

If [available in Hex](https://hex.pm/packages/phoenix_analytics), the package can be installed
by adding `phoenix_analytics` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_analytics, "~> 0.2"}
  ]
end
```

Update `config/config.exs`

```elixir
config :phoenix_analytics,
  duckdb_path: System.get_env("DUCKDB_PATH") || "analytics.duckdb",
  app_domain: System.get_env("PHX_HOST") || "example.com"
```

> [!IMPORTANT]
> In case you have dynamic cluster, you can use your PostgresDB as backend.

```elixir
config :phoenix_analytics,
  duckdb_path: System.get_env("DUCKDB_PATH") || "analytics.duckdb",
  app_domain: System.get_env("PHX_HOST") || "example.com",
  postgres_conn: System.get_env("POSTGRES_CONN") || "dbname=postgres user=phoenix password=analytics host=localhost"
```

> [!IMPORTANT]
> In case you would like to proceed with Postgres option, consider enabling caching.

```elixir
config :phoenix_analytics,
  duckdb_path: System.get_env("DUCKDB_PATH") || "analytics.duckdb",
  app_domain: System.get_env("PHX_HOST") || "example.com",
  postgres_conn: System.get_env("POSTGRES_CONN") || "dbname=postgres user=phoenix password=analytics host=localhost",
  cache_ttl: System.get_env("CACHE_TTL") || 120 # seconds
```

> [!IMPORTANT]
> In case you are hosting your app on fly.io or heroku which doesn't let to persist data on the disk, 
> you can add `in_memory: true` into :phoenix_analytics config. 
> And don't forget to remove `duckdb_path` from the config, otherwise PA will try to create duckdb on the disk. 

```elixir
config :phoenix_analytics,
  app_domain: System.get_env("PHX_HOST") || "example.com",
  postgres_conn: System.get_env("POSTGRES_CONN") || "dbname=postgres user=phoenix password=analytics host=localhost",
  in_memory: true
```

Add migration file

> In case you have ecto less / no migrations project you can do the following:

> `iex -S mix` `PhoenixAnalytics.Migration.up()`

```sh
mix ecto.gen.migration add_phoenix_analytics
```

> [!TIP]
> Based on your configuration migration will be run in appropriate database.
> If only `duckdb_path` then in duckdb file.
> If `duckdb_path` and `postgres_conn` provided then in your Postgres database.

```elixir
defmodule MyApp.Repo.Migrations.AddPhoenixAnalytics do
  use Ecto.Migration

  def up, do: PhoenixAnalytics.Migration.up()
  def down, do: PhoenixAnalytics.Migration.down()
end
```

```sh
mix ecto.migrate
```

Add plug to enable tracking to `endpoint.ex`, ‼️ add it straight after your `Plug.Static`

```elixir
plug PhoenixAnalytics.Plugs.RequestTracker
```

Add dashboard route to your `router.ex`

```elixir
use PhoenixAnalytics.Web, :router

phoenix_analytics_dashboard "/analytics"
```

Update your `.gitignore`

```.gitignore
*.duckdb
*.duckdb.*
```

> [!WARNING]
> ‼️ Please test thoroughly before proceeding to production!

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm/phoenix_analytics). Once published, the docs can
be found at <https://hexdocs.pm/phoenix_analytics>.

Shortcuts:

- `t` -> today
- `ctrl+t` -> yesterday
- `w` -> last_week
- `m` -> last_30_days
- `q` -> last_90_days
- `y` -> last_12_month
- `ctrl+w` -> previous_week
- `ctrl+m` -> previous_month
- `ctrl+q` -> previous_quarter
- `ctrl+y` -> previous_year
- `a` -> all_time

### Development

If you would like to contribute, first you would need to install deps, assets and then compile css and js.
I put everything under next mix command:

```sh
mix setup
```

Then you would need some database with seeds. Here is command for this:

```sh
DUCKDB_PATH="analytics.duckdb" mix run priv/repo/seeds.exs
```

or if you would like to test with Postgres backend:

```sh
cd examples/duck_postgres/

docker compose -f postgres-compose.yml up

# from project root
mix run priv/repo/seeds_postgres.exs
```

> [!NOTE]
> Move database with seeds to example project which you going to use.

Lastly you can use one of example applications to start server.

```sh
cd examples/duck_only/

mix deps.get

mix phx.server
```

You can navigate to `http://localhost:4000/dev/analytics`

## Performance test

I performed [vegeta](https://github.com/tsenart/vegeta) test on basic Macbook Air M2, to see if plug will affect application performance.
Script can be found here: `vegeta/vegeta.sh`

| With plug              | Without                |
| ---------------------- | ---------------------- |
| ![with](/github/vegeta-with.png) | ![without](/github/vegeta-without.png) |

## For whom this library

- [x] Single instance Phoenix app (duckdb only recommended)
- [x] Multiple instances of Phoenix app **without** auto scaling group (duckdb or postgres option can be used)
- [x] Multiple instances of Phoenix app **with** auto scaling group (only postgres powered apps supported at the moment)

### Heavily inspired by

- [error-tracker](https://github.com/elixir-error-tracker/error-tracker)
- [plausible.io](https://plausible.io)
