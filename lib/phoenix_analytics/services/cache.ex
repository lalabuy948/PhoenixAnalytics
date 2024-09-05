defmodule PhoenixAnalytics.Services.Cache do
  @moduledoc """
    This module provides caching functionality for PhoenixAnalytics.

    The main purpose of this cache is to reduce the number of read calls to DuckDB.
    DuckDB is designed for running large queries infrequently, rather than small
    queries often. By caching results, we can improve performance and reduce the
    load on the database for frequently accessed data.

    The cache uses Cachex with a default TTL (Time To Live) of 2 minutes.
  """

  @cache :pa_cache
  @ttl 60 * 2

  @doc false
  def name() do
    @cache
  end

  @doc """
  Retrieves a value from the cache for the given key.

  ## Returns

    * `{:ok, nil}` - If the key is not found in the cache.
    * `{:ok, value}` - If the key is found, where `value` is the cached data.

  ## Examples

      iex> PhoenixAnalytics.Services.Cache.get("some_key")
      {:ok, nil}

      iex> PhoenixAnalytics.Services.Cache.get("existing_key")
      {:ok, "cached_value"}
  """
  def get(key), do: Cachex.get(@cache, key)

  @doc """
  Adds a value to the cache with the given key.

  ## Parameters

    * `key` - The key under which to store the value in the cache.
    * `value` - The value to be stored in the cache.

  ## Returns

    * `{:ok, true}` - If the value was successfully added to the cache.
    * `{:ok, :error}` - If there was an error adding the value to the cache.

  ## Examples

      iex> PhoenixAnalytics.Services.Cache.add("new_key", "new_value")
      {:ok, true}

      iex> PhoenixAnalytics.Services.Cache.add("existing_key", "updated_value")
      {:ok, true}
  """
  def add(key, value), do: Cachex.put(@cache, key, value, ttl: :timer.seconds(@ttl))

  @doc """
  Fetches a value from the cache for the given key, or computes and caches it if not present.

  ## Parameters

    * `key` - The key to fetch from the cache.
    * `callback` - A function that computes the value if it's not in the cache.

    ## Returns

      * `{:ok, value}` - If the value was found in the cache.

      * `{:commit, value}` - If the value was successfully computed and cached.

      * `{:error, reason}` - If there was an error fetching or computing the value.

  ## Examples

      iex> PhoenixAnalytics.Services.Cache.fetch("some_key", fn -> "computed_value" end)
      {:commit, "computed_value"}

      iex> PhoenixAnalytics.Services.Cache.fetch("existing_key", fn -> "new_value" end)
      {:ok, "cached_value"}
  """
  def fetch(key, callback) do
    Cachex.fetch(@cache, key, fn _ -> {:commit, callback.()} end, ttl: :timer.seconds(@ttl))
  end
end
