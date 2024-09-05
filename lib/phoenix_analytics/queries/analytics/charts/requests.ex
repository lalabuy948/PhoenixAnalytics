defmodule PhoenixAnalytics.Queries.Analytics.Charts.Requests do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @table PhoenixAnalytics.Queries.Table.name()
      @valid_intervals ~w(hour day month)s

      def total_requests_per_period(from, to, interval \\ "day")
          when interval in @valid_intervals do
        query = """
        WITH date_series AS (
            SELECT unnest(range(
                    (SELECT GREATEST(MIN(date_trunc('day', inserted_at)), TIMESTAMP '#{from}') FROM #{@table})::TIMESTAMP,
                    TIMESTAMP '#{to}',
                    INTERVAL 1 #{interval}
                )) AS period
        )
        SELECT date_trunc('#{interval}', ds.period)::VARCHAR AS date, count(request_id) as hits,

        FROM date_series ds
        LEFT JOIN #{@table} ON date_trunc('#{interval}', inserted_at) = ds.period
        """

        tail = "GROUP BY ds.period ORDER BY ds.period;"

        query <> tail
      end
    end
  end
end
