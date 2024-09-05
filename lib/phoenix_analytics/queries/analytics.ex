defmodule PhoenixAnalytics.Queries.Analytics do
  @moduledoc false
  use PhoenixAnalytics.Queries.Analytics.Stats.Stat
  use PhoenixAnalytics.Queries.Analytics.Stats.PerPeriod
  use PhoenixAnalytics.Queries.Analytics.Charts.Popular
  use PhoenixAnalytics.Queries.Analytics.Charts.Device
  use PhoenixAnalytics.Queries.Analytics.Charts.Requests
  use PhoenixAnalytics.Queries.Analytics.Charts.Slowest
  use PhoenixAnalytics.Queries.Analytics.Charts.Statuses
  use PhoenixAnalytics.Queries.Analytics.Charts.Visits
end
