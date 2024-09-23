defmodule PhoenixAnalyticsTest do
  use ExUnit.Case
  doctest PhoenixAnalytics

  Code.require_file("./priv/repo/seed_data.exs")

  setup do
    query = PhoenixAnalytics.Queries.Table.create_requests()

    case PhoenixAnalytics.Repo.execute_unsafe(query) do
      {:ok, _} -> :ok
      {:error, reason} -> reason
    end
  end

  test "batcher: insert one" do
    alias PhoenixAnalytics.Services.Batcher

    request_log = SeedData.generate_request_data()

    result =
      case Batcher.send_batch([request_log]) do
        :ok -> :ok
        {:error, reason} -> reason
      end

    assert :ok === result
  end
end
