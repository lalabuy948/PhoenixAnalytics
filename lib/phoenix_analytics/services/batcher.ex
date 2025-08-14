defmodule PhoenixAnalytics.Services.Batcher do
  @moduledoc """
  A GenServer module for batching and inserting RequestLog entries into the database.

  This module provides functionality to efficiently insert RequestLog entries by batching them
  and inserting them in bulk. It uses a GenServer to manage the state of the batch and
  periodically flush the batch to the database.

  The batch is processed and inserted into the database either when it reaches 1_000 logs
  or after 1 second, whichever comes first.

  ## Usage

  To insert a RequestLog:

      PhoenixAnalytics.Services.Batcher.insert(%PhoenixAnalytics.Entities.RequestLog{})

  Alternatively, you can send an event to PubSub for request_log insertion:

      PhoenixAnalytics.Services.PubSub.broadcast(:request_sent, %PhoenixAnalytics.Entities.RequestLog{})

  The module will handle batching and inserting the logs automatically.
  This approach allows for handling distributed app scenarios.
  """

  use GenServer

  alias PhoenixAnalytics.Services.PubSub

  @batch_size 100
  @timeout 1_000

  # --- client callbacks ---

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Inserts a RequestLog into the batch queue.
  The batch is processed and inserted into the database either when it reaches 1_000 logs or after 1 second, whichever comes first.

  ## Parameters

    - request_log: A PhoenixAnalytics.Entities.RequestLog struct to be inserted.

  ## Examples

      iex> PhoenixAnalytics.Services.Batcher.insert(%PhoenixAnalytics.Entities.RequestLog{})

  Note: You can also use PubSub to insert a RequestLog, which is useful for distributed app scenarios:

      iex> PhoenixAnalytics.Services.PubSub.broadcast(:request_sent, %PhoenixAnalytics.Entities.RequestLog{})

  """
  def insert(request_log) do
    GenServer.cast(__MODULE__, {:insert, request_log})
  end

  # --- server callbacks ---

  @doc false
  @impl true
  def init(_state) do
    PubSub.subscribe()

    :timer.send_interval(@timeout, :check_batch)
    {:ok, %{batch: [], last_insert_time: :os.system_time(:millisecond)}}
  end

  @doc false
  @impl true
  def handle_cast({:insert, request_log}, state) do
    new_batch = [request_log | state.batch]

    if length(new_batch) >= @batch_size do
      send_batch(new_batch)

      {:noreply, %{state | batch: [], last_insert_time: :os.system_time(:millisecond)}}
    else
      {:noreply, %{state | batch: new_batch}}
    end
  end

  @doc false
  @impl true
  def handle_info({:request_sent, request_log}, state) do
    GenServer.cast(__MODULE__, {:insert, request_log})
    {:noreply, state}
  end

  @doc false
  @impl true
  def handle_info(:check_batch, state) do
    current_time = :os.system_time(:millisecond)
    time_diff = current_time - state.last_insert_time

    if time_diff >= @timeout && length(state.batch) > 0 do
      send_batch(state.batch)
      {:noreply, %{state | batch: [], last_insert_time: current_time}}
    else
      {:noreply, state}
    end
  end

  @doc """
  Sends a batch of RequestLogs to be inserted into the database.

  ## Parameters

    - batch: A list of PhoenixAnalytics.Entities.RequestLog structs to be inserted.

  ## Examples

      iex> PhoenixAnalytics.Services.Batcher.send_batch([%PhoenixAnalytics.Entities.RequestLog{}, %PhoenixAnalytics.Entities.RequestLog{}])

  """
  def send_batch([]), do: []

  def send_batch(batch) do
    repo = PhoenixAnalytics.Config.get_repo()

    # Convert structs to maps for insert_all
    data =
      Enum.map(batch, fn request_log ->
        request_log
        |> Map.from_struct()
        # Remove Ecto metadata
        |> Map.drop([:__meta__])
        # Set inserted_at timestamp (truncate to seconds precision)
        |> Map.put(:inserted_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
      end)

    repo.insert_all(PhoenixAnalytics.Entities.RequestLog, data, returning: false)
  end
end
