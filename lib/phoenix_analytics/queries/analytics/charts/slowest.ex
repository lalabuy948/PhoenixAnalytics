defmodule PhoenixAnalytics.Queries.Analytics.Charts.Slowest do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import PhoenixAnalytics.Queries.Helpers

      @table PhoenixAnalytics.Queries.Table.name()

      def slowest_pages(from, to) do
        query =
          """
          SELECT {'path': path, 'duration': ROUND(AVG(duration_ms), 2) } FROM #{@table}
          WHERE 1 = 1 AND status_code BETWEEN 200 AND 299
          """

        tail = "GROUP BY path ORDER BY avg(duration_ms) DESC LIMIT 6;"

        query <>
          exclude_non_page() <>
          exlude_dev() <>
          date_filter(from, to) <>
          tail
      end

      def slowest_resources(from, to) do
        query =
          """
          SELECT { 'path': path, 'duration': ROUND(AVG(duration_ms), 2) } FROM #{@table}
          WHERE  status_code = 200
          AND (
            path NOT LIKE '%/%'
          """ <> inclusive_non_page() <> exlude_dev() <> ")"

        tail = """
        GROUP BY path ORDER BY avg(duration_ms) DESC LIMIT 6;
        """

        query <>
          date_filter(from, to) <>
          tail
      end
    end
  end
end
