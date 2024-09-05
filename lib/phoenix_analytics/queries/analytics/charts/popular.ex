defmodule PhoenixAnalytics.Queries.Analytics.Charts.Popular do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import PhoenixAnalytics.Queries.Helpers

      @table PhoenixAnalytics.Queries.Table.name()
      @app_domain Application.compile_env(:phoenix_analytics, :app_domain) ||
                    System.get_env("PHX_HOST") || "example.com"

      def popular_pages(from, to) do
        query =
          """
          SELECT { 'source': path, 'visits': COUNT(*) } FROM #{@table}
          WHERE status_code = 200
          """ <>
            exclude_non_page() <>
            exlude_dev() <>
            date_filter(from, to)

        tail = "\n GROUP BY path ORDER BY COUNT(*) DESC LIMIT 9;"

        query <> tail
      end

      def popular_referer(from, to) do
        query =
          """
          SELECT { 'source': referer, 'visits': COUNT(*) } FROM #{@table}
          WHERE referer NOT LIKE '%#{@app_domain}%' AND referer NOT LIKE '%unknown%'
          """ <>
            date_filter(from, to)

        tail = """
        GROUP BY referer ORDER BY COUNT(*) DESC LIMIT 9;
        """

        query <> tail
      end

      def popular_not_found(from, to) do
        query =
          """
          SELECT { 'source': path, 'visits': COUNT(*) } FROM #{@table}
          WHERE status_code = 404
          """ <>
            date_filter(from, to)

        tail = """
        GROUP BY path ORDER BY COUNT(*) DESC LIMIT 9;
        """

        query <> tail
      end
    end
  end
end
