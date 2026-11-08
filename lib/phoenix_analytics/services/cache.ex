defmodule PhoenixAnalytics.Services.Cache do
  @moduledoc """
    This module provides caching functionality for PhoenixAnalytics.

    The main purpose of this cache is to reduce the number of read calls to the database.
    By caching results, we can improve performance and reduce the load on the database
    for frequently accessed data.

    The cache uses Cachex with a configurable TTL (Time To Live).
  """

  @cache :pa_cache

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
  def add(key, value), do: Cachex.put(@cache, key, value, expire: :timer.seconds(ttl()))

  @doc """
  Returns the cached value for `key`, or computes it with `callback` and caches it.

  Errors raised by `callback` are re-raised (Cachex would otherwise wrap them in a
  `Cachex.Error`), so dashboard components fail loudly inside `assign_async`
  instead of silently rendering "no data". Failed results are never cached.

  ## Examples

      iex> PhoenixAnalytics.Services.Cache.fetch("some_key", fn -> "computed_value" end)
      "computed_value"
  """
  def fetch(key, callback) do
    ttl = ttl()

    if ttl > 0 do
      case Cachex.fetch(@cache, key, fn _ -> {:commit, callback.()} end,
             expire: :timer.seconds(ttl)
           ) do
        {status, value} when status in [:ok, :commit] ->
          value

        {:error, error} ->
          raise "PhoenixAnalytics query #{inspect(key)} failed: #{inspect(error)}"
      end
    else
      callback.()
    end
  end

  defp ttl, do: PhoenixAnalytics.Config.get_cache_ttl()
end
