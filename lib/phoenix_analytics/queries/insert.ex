defmodule PhoenixAnalytics.Queries.Insert do
  @moduledoc false

  alias PhoenixAnalytics.Queries.Table
  alias PhoenixAnalytics.Entities.RequestLog

  @table Table.name()
  @columns ~w(request_id method path status_code duration_ms user_agent remote_ip referer device session_id session_page_views inserted_at)
  @placeholders List.duplicate("?", length(@columns)) |> Enum.join(", ")
  @query "INSERT INTO #{@table} (#{Enum.join(@columns, ", ")}) VALUES (#{@placeholders});"

  @spec insert_one(RequestLog.t()) :: {String.t(), list()}
  def insert_one(%RequestLog{} = request_data) do
    {@query, prepare_values(request_data)}
  end

  @spec insert_many(list(RequestLog.t())) :: {String.t(), list()}
  def insert_many(request_data_list) when is_list(request_data_list) do
    batch_size = length(request_data_list)
    values_placeholders = List.duplicate("(#{@placeholders})", batch_size) |> Enum.join(", ")

    batch_query =
      "INSERT INTO #{@table} (#{Enum.join(@columns, ", ")}) VALUES #{values_placeholders};"

    values = Enum.flat_map(request_data_list, &prepare_values/1)

    {batch_query, values}
  end

  @spec prepare_values(RequestLog.t()) :: list()
  defp prepare_values(%RequestLog{} = request_data) do
    [
      request_data.request_id,
      request_data.method,
      request_data.path,
      request_data.status_code,
      request_data.duration_ms,
      request_data.user_agent,
      request_data.remote_ip,
      request_data.referer,
      request_data.device_type,
      request_data.session_id,
      request_data.session_page_views,
      request_data.inserted_at
    ]
  end
end
