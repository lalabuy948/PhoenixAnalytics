defmodule PhoenixAnalytics.Services.PubSub do
  @moduledoc """
  A module for handling PubSub operations in Phoenix Analytics.

  This module provides a robust and efficient interface for subscribing to and broadcasting
  events related to request analytics. It leverages Phoenix.PubSub under the hood
  to manage pub/sub functionality, enabling seamless communication across distributed
  systems and allowing for load-balanced application sharing of requests.

  """

  alias Phoenix.PubSub

  @pubsub :pa_pubsub
  @topic "request_topic"

  @doc """
  Returns the name of the PubSub server.

  This function provides the atom used to identify the PubSub server. It's useful
  when you need to reference the PubSub server in other parts of your application.

  ## Examples

      iex> PhoenixAnalytics.Services.PubSub.name()
      :pa_pubsub

  ## Return Value

  Returns the atom `:pa_pubsub`.
  """
  @spec name() :: atom()
  def name() do
    @pubsub
  end

  @doc """
  Subscribes the current process to the request topic.

  This function allows a process to receive messages broadcasted to the request topic.
  After subscribing, the process will receive tuples of the form `{:request_sent, event}`
  whenever a new event is broadcasted.

  ## Examples

      iex> PhoenixAnalytics.Services.PubSub.subscribe()
      :ok

  ## Return Value

  Returns `:ok` if the subscription is successful.

  ## Errors

  May raise an error if the PubSub server is not available or if there's an issue with the subscription.
  """
  @spec subscribe() :: :ok | {:error, term()}
  def subscribe() do
    PubSub.subscribe(@pubsub, @topic)
  end

  @doc """
  Broadcasts an event to all subscribers of the request topic.

  This function sends the provided event to all processes that have subscribed to the request topic.
  It's typically used to distribute information about new requests or updates to existing requests.

  ## Parameters

    - event: A `PhoenixAnalytics.Entities.RequestLog` struct representing the event to be broadcasted.

  ## Examples

      iex> request_log = %PhoenixAnalytics.Entities.RequestLog{request_id: "123", path: "/api/users"}
      iex> PhoenixAnalytics.Services.PubSub.broadcast(request_log)
      :ok

  ## Return Value

  Returns `:ok` if the broadcast is successful.

  ## Errors

  May return `{:error, term()}` if there's an issue with broadcasting the message.
  """
  @spec broadcast(PhoenixAnalytics.Entities.RequestLog.t()) :: :ok | {:error, term()}
  def broadcast(event) do
    PubSub.broadcast(@pubsub, @topic, {:request_sent, event})
  end
end
