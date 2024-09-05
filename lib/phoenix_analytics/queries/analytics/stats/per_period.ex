defmodule PhoenixAnalytics.Queries.Analytics.Stats.PerPeriod do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import PhoenixAnalytics.Queries.Helpers

      @table PhoenixAnalytics.Queries.Table.name()
      @valid_intervals ~w(hour day month)s

      def views_per_visit_per_period_limited(from, to, interval \\ "day")
          when interval in @valid_intervals do
        query = """
        WITH date_series AS (
            SELECT unnest(range(
                    (SELECT GREATEST(MIN(date_trunc('day', inserted_at)), TIMESTAMP '#{from}') FROM #{@table})::TIMESTAMP,
                    TIMESTAMP '#{to}',
                    INTERVAL 1 #{interval}
                )) AS period
        ),
        session_data AS (
            SELECT
                date_trunc('day', ds.period) AS period,
                r.session_id,
                MAX(session_page_views) AS page_views
            FROM date_series ds
            LEFT JOIN #{@table} r ON date_trunc('day', r.inserted_at) = date_trunc('day', ds.period)
            WHERE r.session_id IS NOT NULL
            GROUP BY date_trunc('#{interval}', ds.period), r.session_id
        )
        SELECT * FROM (
          SELECT date_trunc('#{interval}', ds.period)::VARCHAR AS date, ROUND(AVG(page_views), 2) AS hits
          FROM date_series ds
          LEFT JOIN session_data ON session_data.period = ds.period
          GROUP BY ds.period ORDER BY ds.period DESC LIMIT #{limit(interval)}
        )
        ORDER BY date ASC;
        """

        query
      end

      def visit_duration_per_period_limited(from, to, interval \\ "day")
          when interval in @valid_intervals do
        query = """
        WITH date_series AS (
            SELECT unnest(range(
                    (SELECT GREATEST(MIN(date_trunc('day', inserted_at)), TIMESTAMP '#{from}') FROM #{@table})::TIMESTAMP,
                    TIMESTAMP '#{to}',
                    INTERVAL 1 #{interval}
                )) AS period
        ),
        session_data AS (
          SELECT
              date_trunc('day', MIN(r.inserted_at)) AS period,
              r.session_id,
              EXTRACT(EPOCH FROM (MAX(r.inserted_at) - MIN(r.inserted_at))) * 1000 AS session_duration
          FROM
              #{@table} r
          WHERE
              r.session_id IS NOT NULL
              AND r.inserted_at >= TIMESTAMP '#{from}'
              AND r.inserted_at <= TIMESTAMP '#{to}'
          GROUP BY r.session_id
          ORDER BY period, session_id
        )
        SELECT * FROM (
          SELECT date_trunc('#{interval}', ds.period)::VARCHAR AS date, ROUND(AVG(sd.session_duration), 2) AS avg_duration

          FROM date_series ds
          LEFT JOIN session_data sd ON date_trunc('day', sd.period) = ds.period

          GROUP BY ds.period ORDER BY ds.period DESC LIMIT #{limit(interval)}
        )
        ORDER BY date ASC;
        """

        query
      end

      def unique_visitors_per_period_limited(from, to, interval \\ "day")
          when interval in @valid_intervals do
        query = """
        WITH date_series AS (
            SELECT unnest(range(
                    TIMESTAMP '#{from}',
                    TIMESTAMP '#{to}',
                    INTERVAL 1 #{interval}
                )) AS period
        )
        SELECT * FROM (
          SELECT date_trunc('#{interval}', ds.period)::VARCHAR AS date, count(DISTINCT remote_ip) as hits,
          FROM date_series ds
          LEFT JOIN #{@table} ON date_trunc('day', inserted_at) = ds.period
          GROUP BY ds.period ORDER BY ds.period DESC LIMIT #{limit(interval)}
        )
        ORDER BY date ASC;
        """

        query
      end

      def total_pageviews_per_period_limited(from, to, interval \\ "day")
          when interval in @valid_intervals do
        query =
          """
          WITH date_series AS (
              SELECT unnest(range(
                      TIMESTAMP '#{from}',
                      TIMESTAMP '#{to}',
                      INTERVAL 1 #{interval}
                  )) AS period
          )
          SELECT * FROM (
            SELECT date_trunc('#{interval}', ds.period)::VARCHAR AS date, count(*) as hits,

            FROM date_series ds
            LEFT JOIN #{@table} ON date_trunc('day', inserted_at) = ds.period AND method = 'GET'
          """ <>
            exclude_non_page()

        tail = """
        GROUP BY ds.period ORDER BY ds.period DESC LIMIT #{limit(interval)})
        ORDER BY date ASC;
        """

        query <> tail
      end

      def total_requests_per_period_limited(from, to, interval \\ "day")
          when interval in @valid_intervals do
        query = """
        WITH date_series AS (
            SELECT unnest(range(
                    TIMESTAMP '#{from}',
                    TIMESTAMP '#{to}',
                    INTERVAL 1 #{interval}
                )) AS period
        )
        SELECT * FROM (
          SELECT date_trunc('#{interval}', ds.period)::VARCHAR AS date, count(*) as hits,

          FROM date_series ds
          LEFT JOIN #{@table} ON date_trunc('day', inserted_at) = ds.period

          GROUP BY ds.period ORDER BY ds.period DESC LIMIT #{limit(interval)}
        )
        ORDER BY date ASC;
        """

        query
      end

      def bounce_rate_per_period_limited(from, to, interval \\ "day")
          when interval in @valid_intervals do
        query = """
        WITH date_series AS (
          SELECT unnest(range(
                  (SELECT GREATEST(MIN(date_trunc('day', inserted_at)), TIMESTAMP '#{from}') FROM #{@table})::TIMESTAMP,
                  TIMESTAMP '#{to}',
                  INTERVAL 1 #{interval}
              )) AS period
        ),
        session_data AS (
          SELECT
            date_trunc('day', inserted_at) AS period,
            session_id,
            session_page_views
          FROM #{@table}
          WHERE inserted_at >= TIMESTAMP '#{from}'
            AND inserted_at <= TIMESTAMP '#{to}'
        )
        SELECT * FROM (
          SELECT date_trunc('#{interval}', ds.period)::VARCHAR AS date,
            ROUND(100.0 * SUM(CASE WHEN sd.session_page_views = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS bounce_rate
          FROM date_series ds
          LEFT JOIN session_data sd ON date_trunc('day', sd.period) = ds.period
          GROUP BY ds.period ORDER BY ds.period LIMIT #{limit(interval)}
        )
        ORDER BY date ASC;
        """

        query
      end

      def limit(interval) when interval in @valid_intervals do
        case interval do
          "hour" -> 24
          "day" -> 7
          "month" -> 12
        end
      end
    end
  end
end
