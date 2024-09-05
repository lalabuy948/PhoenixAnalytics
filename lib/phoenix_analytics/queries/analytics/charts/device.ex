defmodule PhoenixAnalytics.Queries.Analytics.Charts.Device do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import PhoenixAnalytics.Queries.Helpers

      @table PhoenixAnalytics.Queries.Table.name()

      def devices_usage(from, to) do
        query =
          """
          SELECT DISTINCT device, count(*) FROM #{@table}
          WHERE 1=1
          """ <>
            exclude_non_page() <>
            exlude_dev() <>
            date_filter(from, to)

        tail = "\n GROUP BY device;"

        query <> tail
      end
    end
  end
end
