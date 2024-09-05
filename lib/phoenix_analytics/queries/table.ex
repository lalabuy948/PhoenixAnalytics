defmodule PhoenixAnalytics.Queries.Table do
  @moduledoc false

  @requests "requests"

  def name() do
    @requests
  end

  def create_requests do
    query = """
    CREATE TABLE IF NOT EXISTS #{@requests} (
      request_id UUID PRIMARY KEY,
      method VARCHAR NOT NULL,
      path VARCHAR NOT NULL,
      status_code SMALLINT NOT NULL,
      duration_ms REAL NOT NULL,
      user_agent VARCHAR,
      remote_ip VARCHAR,
      referer VARCHAR,
      device VARCHAR,
      session_id UUID,
      session_page_views INTEGER,
      inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """

    query
  end

  def drop_requests do
    query = "DROP TABLE IF EXISTS #{@requests};"

    query
  end
end
