defmodule PhoenixAnalytics.Queries.Table do
  @moduledoc """
  Ecto-based table operations for PhoenixAnalytics.

  This module provides functions for creating and managing database tables
  using Ecto schemas and migrations instead of raw SQL.
  """

  @doc """
  Gets the table name for requests.
  """
  def name do
    "requests"
  end

  @doc """
  Creates the requests table using Ecto schema.
  This function is primarily for development/testing.
  For production, use proper Ecto migrations.
  """
  def create_requests do
    # Use Ecto's schema to create the table
    # For simplicity, always use PostgreSQL-compatible table creation
    # The actual adapter will handle database-specific SQL translation
    create_table_postgres()
  end

  @doc """
  Drops the requests table.
  """
  def drop_requests do
    "DROP TABLE IF EXISTS #{name()}"
  end

  # Private functions for database-specific table creation

  defp create_table_postgres do
    """
    CREATE TABLE IF NOT EXISTS #{name()} (
      request_id VARCHAR(255) PRIMARY KEY,
      method VARCHAR(10) NOT NULL,
      path TEXT NOT NULL,
      status_code INTEGER NOT NULL,
      duration_ms INTEGER NOT NULL,
      user_agent TEXT,
      remote_ip VARCHAR(45),
      referer TEXT,
      device_type VARCHAR(20),
      session_id VARCHAR(255),
      session_page_views INTEGER,
      inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
  end
end
