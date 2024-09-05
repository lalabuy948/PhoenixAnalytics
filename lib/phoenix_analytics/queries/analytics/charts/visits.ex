defmodule PhoenixAnalytics.Queries.Analytics.Charts.Visits do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import PhoenixAnalytics.Queries.Helpers

      @table PhoenixAnalytics.Queries.Table.name()
      @valid_intervals ~w(hour day month)s

      def visits_per_period(from, to, interval \\ "day") when interval in @valid_intervals do
        query =
          """
          WITH date_series AS (
              SELECT unnest(range(
                      (SELECT GREATEST(MIN(date_trunc('day', inserted_at)), TIMESTAMP '#{from}') FROM #{@table})::TIMESTAMP,
                      TIMESTAMP '#{to}',
                      INTERVAL 1 #{interval}
                  )) AS period
          )
          SELECT
            date_trunc('#{interval}', ds.period)::VARCHAR,
            count(remote_ip),
            count(DISTINCT remote_ip)

          FROM date_series ds

          LEFT JOIN #{@table} ON datetrunc('#{interval}', inserted_at) = datetrunc('#{interval}', ds.period)
          """ <>
            exclude_non_page()

        tail = "GROUP BY ds.period ORDER BY ds.period;"

        query <> tail
      end
    end
  end
end
