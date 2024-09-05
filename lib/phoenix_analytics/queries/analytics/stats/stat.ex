defmodule PhoenixAnalytics.Queries.Analytics.Stats.Stat do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import PhoenixAnalytics.Queries.Helpers

      @table PhoenixAnalytics.Queries.Table.name()
      @valid_intervals ~w(day month year)s

      def unique_visitors(from, to) do
        query =
          """
          SELECT count(DISTINCT remote_ip) FROM #{@table}
          WHERE 1=1
          """ <>
            date_filter(from, to)

        query
      end

      def total_pageviews(from, to) do
        query =
          """
          SELECT count(*) FROM #{@table}
          WHERE method = 'GET'
          """ <>
            exclude_non_page() <>
            date_filter(from, to)

        query
      end

      def total_requests(from, to) do
        query =
          """
          SELECT count(*) FROM #{@table}
          WHERE 1=1
          """ <>
            date_filter(from, to)

        query
      end

      def average_views_per_visit(from, to) do
        query =
          """
          SELECT ROUND(AVG(session_page_views), 2) FROM #{@table}
          WHERE 1=1
          """ <>
            date_filter(from, to)

        query
      end

      def average_visit_duration(from, to, interval \\ "day") when interval in @valid_intervals do
        query = """
        SELECT ROUND(AVG(session_duration), 2) AS avg_duration
        FROM (
          SELECT
            session_id,
            EXTRACT(EPOCH FROM (MAX(inserted_at) - MIN(inserted_at))) * 1000 AS session_duration
          FROM #{@table}
          WHERE inserted_at >= TIMESTAMP '#{from}'
            AND inserted_at <= TIMESTAMP '#{to}'
          GROUP BY session_id
        ) AS session_max_durations;
        """

        query
      end

      def bounce_rate(from, to) do
        query = """
        WITH session_data AS (
          SELECT
            session_id,
            session_page_views
          FROM #{@table}
          WHERE inserted_at >= TIMESTAMP '#{from}'
            AND inserted_at <= TIMESTAMP '#{to}'
        )
        SELECT
          ROUND(100.0 * SUM(CASE WHEN session_page_views = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS bounce_rate
        FROM session_data;
        """

        query
      end
    end
  end
end
