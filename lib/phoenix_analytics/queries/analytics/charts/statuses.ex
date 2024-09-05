defmodule PhoenixAnalytics.Queries.Analytics.Charts.Statuses do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @table PhoenixAnalytics.Queries.Table.name()
      @valid_intervals ~w(hour day month)s

      def statuses_per_period(from, to, interval \\ "day") when interval in @valid_intervals do
        query = """
        WITH date_series AS (
            SELECT unnest(range(
                    (SELECT GREATEST(MIN(date_trunc('day', inserted_at)), TIMESTAMP '#{from}') FROM #{@table})::TIMESTAMP,
                    TIMESTAMP '#{to}',
                    INTERVAL 1 #{interval}
                )) AS period
        )
        SELECT
            date_trunc('#{interval}', ds.period)::VARCHAR AS date,
            SUM(CASE WHEN status_code BETWEEN 200 AND 299 THEN 1 ELSE 0 END),
            SUM(CASE WHEN status_code BETWEEN 300 AND 399 THEN 1 ELSE 0 END),
            SUM(CASE WHEN status_code BETWEEN 400 AND 499 THEN 1 ELSE 0 END),
            SUM(CASE WHEN status_code BETWEEN 500 AND 599 THEN 1 ELSE 0 END),

        FROM date_series ds

        LEFT JOIN #{@table} ON datetrunc('#{interval}', inserted_at) = datetrunc('#{interval}', ds.period)
        GROUP BY ds.period ORDER BY ds.period;
        """

        query
      end
    end
  end
end
