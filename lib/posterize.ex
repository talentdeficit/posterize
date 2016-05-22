defmodule :posterize do
  @moduledoc """
  an erlang API for postgrex
  """

  @typedoc """
  a connection process name, pid or reference.

  a connection reference is used when making multiple requests to the same
  connection, see `transaction/3` and `after_connect` in `start_link/1`.
  """
  @type conn :: DBConnection.conn | {:sbroker, DBConnection.conn} | {:poolboy, DBConnection.conn}

  @pool_timeout 5000
  @timeout 5000
  @idle_timeout 5000

  ### PUBLIC API ###

  @doc """
  start the connection process and connect to postgres

  ## options

  options are a proplist where the following keys are valid

    * `hostname` - server hostname (default: PGHOST env variable, then localhost);
    * `port` - server port (default: 5432);
    * `database` - database (required);
    * `username` - username (default: PGUSER env variable, then USER env var);
    * `password` - user password (default PGPASSWORD);
    * `parameters` - proplist of connection parameters;
    * `timeout` - connect timeout in milliseconds (default: `#{@timeout}`);
    * `ssl` - set to `true` if ssl should be used (default: `false`);
    * `ssl_opts` - a list of ssl options, see ssl docs;
    * `socket_options` - options to be given to the underlying socket;
    * `sync_connect` - block in `start_link/1` until connection is set up (default: `false`)
    * `extensions` - a list of `{Module, Opts}` pairs where `Module` is
      implementing the `Postgrex.Extension` behaviour and `Opts` are the
      extension options;
    * `after_connect` - a function to run on connect, either a 1-arity fun
    called with a connection reference, `{Module, Function, Args}` with the
    connection reference prepended to `Args` or `nil`, (default: `nil`)
    * `idle_timeout` - idle timeout to ping postgres to maintain a connection
    (default: `#{@idle_timeout}`)
    * `backoff_start` - the first backoff interval when reconnecting (default:
    `200`);
    * `backoff_max` - the maximum backoff interval when reconnecting (default:
    `15_000`);
    * `backoff_type` - the backoff strategy when reconnecting, `stop` for no
    backoff and to stop (see `backoff`, default: `jitter`)
    * `transactions` - set to `strict` to error on unexpected transaction
    state, otherwise set to `naive` (default: `naive`);
    * `pool_size` - the max size of the connection pool (default: 10);
  """
  @spec start_link(Keyword.t) :: {:ok, pid} | {:error, Postgrex.Error.t | term}
  def start_link(opts) do
    opts = Keyword.put(opts, :pool, DBConnection.Sojourn)

    # use :null as the default null value, instead of nil
    opts = Keyword.update(opts, :null, :null, &(&1))

    opts = Keyword.update(opts, :extensions, default_xts, &(&1 ++ default_xts))
    
    {:ok, conn} = Postgrex.start_link(opts)
    {:ok, {:sbroker, conn}}
  end
  
  defp default_xts, do: :posterize_xt_datetime_utils.stack

  @doc """
  runs an (extended) query and returns the result as `{ok, Result}`
  or `{error, Error}` if there was an error. parameters can be
  set in the query as `$1` embedded in the query string. parameters are given as
  a list of erlang values. see the README for information on how postergirl
  encodes and decodes erlang values by default

  ## options
  
  options are a proplist where the following keys are valid

    * `pool_timeout` - time to wait in the queue for the connection
    (default: `#{@pool_timeout}`)
    * `queue` - whether to wait for connection in a queue (default: `true`);
    * `timeout` - query request timeout (default: `#{@timeout}`);
    * `decode_mapper` - fun to map each row in the result to a term after
    decoding, (default: `fun(X) -> X end`);

  ## examples

      posterize:query(Conn, "CREATE TABLE posts (id serial, title text)", []).

      posterize:query(Conn, "INSERT INTO posts (title) VALUES ('my title')", []).

      posterize:query(Conn, "SELECT title FROM posts", []).

      posterize:query(Conn, "SELECT id FROM posts WHERE title like $1", [<<"%my%">>]).
  """
  @spec query(conn, iodata, list, Keyword.t) :: {:ok, Postgrex.Result.t} | {:error, String.t}
  def query({:sbroker, conn}, statement, params, opts) do
    Postgrex.query(conn, statement, params, [pool: DBConnection.Sojourn] ++ opts)
  end
  def query({:poolboy, conn}, statement, params, opts) do
    Postgrex.query(conn, statement, params, [pool: DBConnection.Poolboy] ++ opts)
  end
  def query(conn, statement, params, opts) do
    Postgrex.query(conn, statement, params, opts)
  end

  def query(conn, statement, params), do: query(conn, statement, params, [])


  @doc """
  prepares an (extended) query and returns the result as
  `{ok, Result}` or `{error, Error}` if there was an
  error. parameters can be set in the query as `$1` embedded in the query
  string. to execute the query call `execute/4`. to close the prepared query
  call `close/3`

  ## options

  options are a proplist where the following keys are valid

    * `pool_timeout` - Time to wait in the queue for the connection
    (default: `#{@pool_timeout}`)
    * `queue` - Whether to wait for connection in a queue (default: `true`);
    * `timeout` - Prepare request timeout (default: `#{@timeout}`);

  ## examples

      {ok, Query} = posterize:prepare(Conn, "CREATE TABLE posts (id serial, title text)").
  """
  @spec prepare(conn, iodata, iodata, Keyword.t) :: {:ok, Postgrex.Query.t} | {:error, Postgrex.Error.t}
  def prepare({:sbroker, conn}, name, statement, opts) do
    Postgrex.prepare(conn, name, statement, [pool: DBConnection.Sojourn] ++ opts)
  end
  def prepare({:poolboy, conn}, name, statement, opts) do
    Postgrex.prepare(conn, name, statement, [pool: DBConnection.Poolboy] ++ opts)
  end
  def prepare(conn, name, statement, opts) do
    Postgrex.prepare(conn, name, statement, opts)
  end

  def prepare(conn, name, statement), do: prepare(conn, name, statement, [])

  @doc """
  runs an (extended) prepared query and returns the result as
  `{ok, Result}` or `{error, Error}` if there was an
  error. parameters are given as part of the prepared query, `%Postgrex.Query{}`.
  See the README for information on how Postgrex encodes and decodes Elixir
  values by default. See `Postgrex.Query` for the query data and
  `Postgrex.Result` for the result data.

  ## options
  
  options are a proplist where the following keys are valid

    * `pool_timeout` - Time to wait in the queue for the connection
    (default: `#{@pool_timeout}`)
    * `queue` - Whether to wait for connection in a queue (default: `true`);
    * `timeout` - Execute request timeout (default: `#{@timeout}`);
    * `decode_mapper` - Fun to map each row in the result to a term after
    decoding, (default: `fun(X) -> X end`);

  ## Examples

      {ok, Query} = posterize:prepare(Conn, "CREATE TABLE posts (id serial, title text)"),
      {ok, Result} = posterize:execute(Conn, Query, []).

      {ok, Query} = posterize:prepare(Conn, "SELECT id FROM posts WHERE title like $1"),
      {ok, Result} = posterize:execute(Conn, Query, [<<"%my%">>]).
  """
  @spec execute(conn, Postgrex.Query.t, list, Keyword.t) ::
    {:ok, Postgrex.Result.t} | {:error, Postgrex.Error.t}
  def execute({:sbroker, conn}, query, params, opts) do
    Postgrex.execute(conn, query, params, [pool: DBConnection.Sojourn] ++ opts)
  end
  def execute({:poolboy, conn}, query, params, opts) do
    Postgrex.execute(conn, query, params, [pool: DBConnection.Poolboy] ++ opts)
  end
  def execute(conn, query, params, opts) do
    Postgrex.execute(conn, query, params, opts)
  end

  def execute(conn, query, params), do: execute(conn, query, params, [])


  @doc """
  Closes an (extended) prepared query and returns `ok` or
  `{error, Error`} if there was an error. Closing a query releases
  any resources held by postgresql for a prepared query with that name. See
  `Postgrex.Query` for the query data.
  
  ## options

  options are a proplist where the following keys are valid
  
    * `pool_timeout` - Time to wait in the queue for the connection
    (default: `#{@pool_timeout}`)
    * `queue` - Whether to wait for connection in a queue (default: `true`);
    * `timeout` - Close request timeout (default: `#{@timeout}`);
  
  ## examples

      {ok, Query} = posterize:prepare(Conn, "CREATE TABLE posts (id serial, title text)"),
      ok = posterize:close(Conn, Query).
  """
  @spec close(conn, Postgrex.Query.t, Keyword.t) :: :ok | {:error, Postgrex.Error.t}
  def close({:sbroker, conn}, query, opts) do
    Postgrex.close(conn, query, [pool: DBConnection.Sojourn] ++ opts)
  end
  def close({:poolboy, conn}, query, opts) do
    Postgrex.close(conn, query, [pool: DBConnection.Poolboy] ++ opts)
  end
  def close(conn, query, opts) do
    Postgrex.close(conn, query, opts)
  end

  def close(conn, query), do: close(conn, query, [])


  @doc """
  acquire a lock on a connection and run a series of requests inside a
  transaction. the result of the transaction fun is return inside an `ok`
  tuple: `{ok, Result}`
  
  to use the locked connection call the request with the connection
  reference passed as the single argument to the `Fun`. if the
  connection disconnects all future calls using that connection
  reference will fail
  `rollback/2` rolls back the transaction and causes the function to
  return `{error, Error}`
  `transaction/3` can be nested multiple times if the connection
  reference is used to start a nested transaction. the top level
  transaction function is the actual transaction
  
  ## options
  
  options are a proplist where the following keys are valid  
  
    * `pool_timeout` - Time to wait in the queue for the connection
    (default: `#{@pool_timeout}`)
    * `queue` - Whether to wait for connection in a queue (default: `true`);
    * `timeout` - Transaction timeout (default: `#{@timeout}`);
    * `mode` - Set to `savepoint` to use savepoints instead of an SQL
    transaction, otherwise set to `transaction` (default: `transaction`);
  
  the `timeout` is for the duration of the transaction and all nested
  transactions and requests. this timeout overrides timeouts set by internal
  transactions and requests. the `pool` and `mode` will be used for all
  requests inside the transaction function
  
  ## example

      Fun = fun(Conn) -> posterize:query(Conn, "SELECT title FROM posts", []) end,
      {ok, Result} = posterize:transaction(Conn, Fun).
  """
  @spec transaction(conn, ((DBConnection.t) -> result), Keyword.t) ::
    {:ok, result} | {:error, any} when result: var
  def transaction({:sbroker, conn}, fun, opts) do
    Postgrex.transaction(conn, fun, [pool: DBConnection.Sojourn] ++ opts)
  end
  def transaction({:poolboy, conn}, fun, opts) do
    Postgrex.transaction(conn, fun, [pool: DBConnection.Poolboy] ++ opts)
  end 
  def transaction(conn, fun, opts) do
    Postgrex.transaction(conn, fun, opts)
  end

  def transaction(conn, fun), do: transaction(conn, fun, [])

  @doc """
  rollback a transaction, does not return
  aborts the current transaction fun. if inside multiple `transaction/3`
  functions, bubbles up to the top level
  
  ## example
      {error, oops} = posterize:transaction(Conn, fun(Conn) ->
        posterize:rollback(Conn, :bar),
        io:format("never reaches here!", [])
      end).
  """
  @spec rollback(DBConnection.t, any) :: no_return()
  defdelegate rollback(conn, any), to: DBConnection


  @doc """
  returns a cached map of connection parameters.

  ## options

  options are a proplist where the following keys are valid 

    * `timeout` - Call timeout (default: `#{@timeout}`)
  """
  @spec parameters(pid, Keyword.t) :: map
  def parameters(pid, opts \\ []), do: Postgrex.parameters(pid, opts)
end