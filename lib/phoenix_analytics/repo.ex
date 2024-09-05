defmodule PhoenixAnalytics.Repo do
  @moduledoc """
  A custom repository module for the PhoenixAnalytics project.

  This module maintains write and read connections to a DuckDB database using GenServer,
  and provides functions to execute queries, insert data, and manage the connection.

  The repository handles both safe (parameterized) and unsafe query execution,
  as well as batch inserts using the DuckDB appender.

  The database connections are stored in the GenServer state and can be accessed
  using the `get_connection/0` or `get_read_connection/0` functions.
  """

  use GenServer
  alias PhoenixAnalytics.Services.Telemetry

  @table PhoenixAnalytics.Queries.Table.name()
  @db_path Application.compile_env(:phoenix_analytics, :database_path) ||
             System.get_env("DUCK_PATH")

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Retrieves the current DuckDB connection from the GenServer state.

  This function sends a synchronous call to the GenServer to get the current
  database connection stored in its state.

  ## Returns

    * `{:ok, connection}` - If the connection is successfully retrieved.
    * `{:error, reason}` - If there's an error retrieving the connection.

  ## Examples

      iex> PhoenixAnalytics.Repo.get_connection()
      {:ok, %Duckdbex.Connection{}}

  """
  def get_connection do
    GenServer.call(__MODULE__, :get_connection)
  end

  @doc """
  Retrieves the current `read` DuckDB connection from the GenServer state.

  This function sends a synchronous call to the GenServer to get the current
  database connection stored in its state.

  ## Returns

    * `{:ok, connection}` - If the connection is successfully retrieved.
    * `{:error, reason}` - If there's an error retrieving the connection.

  ## Examples

      iex> PhoenixAnalytics.Repo.get_read_connection()
      {:ok, %Duckdbex.Connection{}}

  """
  def get_read_connection do
    GenServer.call(__MODULE__, :get_read_connection)
  end

  # --- server callbacks ---

  @doc """
  Initializes the GenServer state with a DuckDB connection.

  This function opens a DuckDB database connection using the path specified in the
  application configuration. If the connection is successfully established, it
  returns the initial state with the connection.

  ## Returns

    * `{:ok, state}` - If the database connection is successfully established.
    * `{:stop, reason}` - If there's an error opening the database or creating a connection.

  ## Notes

    * If `@db_path` is `nil`, the application will fail to start. Ensure that a valid
      database path is configured in the application environment.

  """
  def init(_state) do
    with {:ok, db} <- Duckdbex.open(@db_path),
         {:ok, conn} = Duckdbex.connection(db),
         {:ok, read_conn} = Duckdbex.connection(db) do
      {:ok, %{connection: conn, read_connection: read_conn}}
    else
      {:error, reason} ->
        Telemetry.log_error(:repo, reason)
        {:stop, reason}
    end
  end

  @doc false
  def handle_call(:get_connection, _from, state) do
    {:reply, {:ok, state.connection}, state}
  end

  @doc false
  def handle_call(:get_read_connection, _from, state) do
    {:reply, {:ok, state.read_connection}, state}
  end

  @doc """
  Executes an unsafe query on the DuckDB connection.

  This function retrieves the database connection and executes the given query
  without any parameter binding. It should be used with caution, as it may be
  vulnerable to SQL injection if used with user-supplied input.

  ## Parameters

    * `query` - A string containing the SQL query to be executed.

  ## Returns

    * `{:ok, result}` - If the query is successfully executed.
    * `{:error, reason}` - If there's an error retrieving the connection or executing the query.

  ## Examples

      iex> PhoenixAnalytics.Repo.execute_unsafe("SELECT * FROM users")
      {:ok, %Duckdbex.Result{}}

  """
  def execute_unsafe(query) do
    case get_connection() do
      {:ok, conection} ->
        Duckdbex.query(conection, query)

      {:error, reason} ->
        Telemetry.log_error(:repo, reason)
        {:error, reason}
    end
  end

  @doc """
  Executes a safe (parameterized) query on the DuckDB connection.

  This function retrieves the database connection, prepares a statement with the given query,
  and executes it with the provided parameters. This method is preferred over `execute_unsafe/1`
  as it helps prevent SQL injection attacks.

  ## Parameters

    * `{query, params}` - A tuple containing the SQL query string and a list of parameters.

  ## Returns

    * `{:ok, result}` - If the query is successfully executed.
    * `{:error, reason}` - If there's an error retrieving the connection or executing the query.

  ## Examples

      iex> PhoenixAnalytics.Repo.execute_safe({"SELECT * FROM users WHERE id = ?", [1]})
      {:ok, %Duckdbex.Result{}}

  """
  def execute_safe({query, params}) do
    case get_connection() do
      {:ok, conection} ->
        {:ok, stmt_ref} = Duckdbex.prepare_statement(conection, query)

        Duckdbex.execute_statement(stmt_ref, params)

      {:error, reason} ->
        Telemetry.log_error(:repo, reason)
        {:error, reason}
    end
  end

  @doc """
  Inserts multiple rows into the database using the DuckDB appender.

  This function retrieves the database connection, creates an appender for the specified table,
  and adds multiple rows to the table in a batch operation. This method is more efficient
  for inserting large amounts of data compared to individual inserts.

  ## Parameters

    * `batch` - A list of rows to be inserted into the table.

  ## Returns

    * `{:ok, result}` - If the batch insert is successful.
    * `{:error, reason}` - If there's an error retrieving the connection or performing the batch insert.

  ## Examples

      iex> batch = [["John", 30], ["Jane", 25]]
      iex> PhoenixAnalytics.Repo.insert_many(batch)
      :ok

  For performance testing, you can run `../priv/repo/seeds.exs` locally.
  """
  def insert_many(batch) do
    case get_connection() do
      {:ok, conection} ->
        {:ok, appender} = Duckdbex.appender(conection, @table)

        Duckdbex.appender_add_rows(appender, batch)

      {:error, reason} ->
        Telemetry.log_error(:repo, reason)
        {:error, reason}
    end
  end

  @doc """
  Executes a safe (parameterized) query on the DuckDB connection and fetches all results.

  This function retrieves the database connection, prepares a statement with the given query,
  executes it with the provided parameters, and fetches all results.

  ## Parameters

    * `{query, params}` - A tuple containing the SQL query string and a list of parameters.

  ## Returns

    * `results` - If the query is successfully executed and results are fetched.
    * `{:error, reason}` - If there's an error retrieving the connection, executing the query, or fetching results.

  ## Examples

      iex> PhoenixAnalytics.Repo.execute_fetch({"SELECT * FROM users WHERE age > ?", [25]})
      [%{"name" => "John", "age" => 30}, %{"name" => "Jane", "age" => 28}]

  """
  def execute_fetch({query, params}) do
    case get_read_connection() do
      {:ok, conection} ->
        {:ok, stmt_ref} = Duckdbex.prepare_statement(conection, query)
        {:ok, result_ref} = Duckdbex.execute_statement(stmt_ref, params)

        Duckdbex.fetch_all(result_ref)

      {:error, reason} ->
        Telemetry.log_error(:repo, reason)
        {:error, reason}
    end
  end
end
