defmodule :posterize do
  @moduledoc """
  an erlang API for postgrex, a postgres client
  """

  @typedoc """
  a connection process name, pid or reference

  a connection reference is used when making multiple requests to the same
  connection, see `transaction/3`
  """
  @type conn :: DBConnection.conn | {:sbroker, DBConnection.conn} | {:poolboy, DBConnection.conn}

  @pool_timeout 5000
  @timeout 15000
  @max_rows 500

  ### PUBLIC API ###


  @doc """
  start the connection process and connect to postgres

  ## options

    * `hostname` - server hostname (default: PGHOST env variable, then localhost);
    * `port` - server port (default: PGPORT env variable, then 5432);
    * `database` - database (required);
    * `username` - username (default: PGUSER env variable, then USER env var);
    * `password` - user password (default PGPASSWORD env variable);
    * `parameters` - proplist of connection parameters;
    * `timeout` - connect timeout in milliseconds (default: `#{@timeout}`);
    * `ssl` - set to `true` if ssl should be used (default: `false`);
    * `ssl_opts` - a list of ssl options, see ssl docs;
    * `socket_options` - options to be given to the underlying socket;
    * `sync_connect` - block in `start_link/1` until connection is set up (default: `false`)
    * `extensions` - a list of `{Module, Opts}` pairs where `Module` is
    an implemention of the `Postgrex.Extension` behaviour and `Opts` are the
    extension options;
    * `decode_binary` - either `copy` to copy binary values when decoding with
    default extensions that return binaries or `reference` to use a reference
    counted binary of the binary received from the socket. referencing a
    potentially larger binary can be more efficient if the binary value is going
    to be garbage collected soon because a copy is avoided. however the larger
    binary can not be garbage collected until all the refences are garbage
    collected (defaults to `copy`);
    * `prepare` - how to prepare queries, either `named` to use named queries
    or unnamed to force unnamed queries (default: `named`);
    * `transactions` - set to `strict` to error on unexpected transaction state,
    otherwise set to `naive` (default: `naive`);
    * `pool` - the pool module to use, see `DBConnection` for pool dependent
    options, this option must be included with all requests contacting the pool
    if not `DBConnection.Connection` (default: `'Elixir.DBConnection.Sojourn'`);
    * `null` - the atom to use as a stand in for postgres' `NULL` in encoding
    and decoding (default: `null`);

    `Postgrex` (and posterize) use the `DBConnection` framework and support all
    `DBConnection` options. see `DBConnection` for more information
  """
  @spec start_link(Keyword.t) :: {:ok, pid} | {:error, Postgrex.Error.t | term}
  def start_link(opts) do
    # use sbroker as the default pool
    opts = Keyword.put_new(opts, :pool, DBConnection.Sojourn)
    # use :null as the default null value, instead of nil
    opts = Keyword.put_new(opts, :null, :null)
    # append default extensions after user extensions
    opts = Keyword.update(opts, :extensions, default_xts, &(&1 ++ default_xts))
    
    Postgrex.start_link(opts)
  end
  
  defp default_xts, do: :posterize_xt_datetime_utils.stack


  @doc """
  runs an (extended) query and returns the result as `{ok, Result}`
  or `{error, Error}` if there was a database error. parameters can be
  set in the query as `$1` embedded in the query string. parameters are given as
  a list of erlang values. see the README for information on how posterize
  encodes and decodes erlang values by default. see `Postgrex.Result` for the
  result data

  ## options

    * `pool_timeout` - time to wait in the queue for the connection
    (default: `#{@pool_timeout}`)
    * `queue` - whether to wait for connection in a queue (default: `true`);
    * `timeout` - query request timeout (default: `#{@timeout}`);
    * `decode_mapper` - fun to map each row in the result to a term after
    decoding, (default: `fun(X) -> X end`);
    * `pool` - the pool module to use, must match that set on `start_link/1`
    (default: `'Elixir.DBConnection.Sojourn'`);
    * `null` - the atom to use as a stand in for postgres' `NULL` in encoding
    and decoding (default: `null`);
    * `mode` - set to `savepoint` to use a savepoint to rollback to before the
    query on error, otherwise set to `transaction` (default: `transaction`);
    * `copy_data` - whether to add copy data as a final parameter for use with
    `COPY .. FROM STDIN` queries, if the query is not copying to the database
    the data is sent but silently discarded (default: `false`);

  ## examples

      posterize:query(Conn, "CREATE TABLE posts (id serial, title text)", []).

      posterize:query(Conn, "INSERT INTO posts (title) VALUES ('my title')", []).

      posterize:query(Conn, "SELECT title FROM posts", []).

      posterize:query(Conn, "SELECT id FROM posts WHERE title like $1", [<<"%my%">>]).

      posterize:query(Conn, "COPY posts TO STDOUT", []).

      posterize:query(Conn, "COPY ints FROM STDIN", ["1\\n2\\n3\\n"], [copy_data: true])
  """
  @spec query(conn, iodata, list, Keyword.t) :: {:ok, Postgrex.Result.t} | {:error, String.t}
  def query(conn, statement, params, opts) do
    # use sbroker as the default pool
    opts = Keyword.put_new(opts, :pool, DBConnection.Sojourn)
    # use :null as the default null value, instead of nil
    opts = Keyword.put_new(opts, :null, :null)

    Postgrex.query(conn, statement, params, opts)
  end

  def query(conn, statement, params), do: query(conn, statement, params, [])


  @doc """
  prepares an (extended) query and returns a prepared query as `{ok, Query}`
  or `{error, Error}` if there was an error. execute the returned query with
  `execute/3,4`

  ## options
  see `query/3,4`

  ## examples

      {ok, Query} = posterize:prepare(Conn, "name", "CREATE TABLE posts (id serial, title text)").
  """
  @spec prepare(conn, iodata, iodata, Keyword.t) :: {:ok, Postgrex.Query.t} | {:error, Postgrex.Error.t}
  def prepare(conn, name, statement, opts) do
    # use sbroker as the default pool
    opts = Keyword.put_new(opts, :pool, DBConnection.Sojourn)
    # use :null as the default null value, instead of nil
    opts = Keyword.put_new(opts, :null, :null)

    Postgrex.prepare(conn, name, statement, opts)
  end

  def prepare(conn, name, statement), do: prepare(conn, name, statement, [])


  @doc """
  runs an (extended) prepared query and returns the result as `{ok, Result}`
  or `{error, Error}` if there was an error

  ## options
  see `query/3,4`

  ## examples

      {ok, Query} = posterize:prepare(Conn, "", "CREATE TABLE posts (id serial, title text)"),
      {ok, Result} = posterize:execute(Conn, Query, []).

      {ok, Query} = posterize:prepare(Conn, "", "SELECT id FROM posts WHERE title like $1"),
      {ok, Result} = posterize:execute(Conn, Query, [<<"%my%">>]).
  """
  @spec execute(conn, Postgrex.Query.t, list, Keyword.t) ::
    {:ok, Postgrex.Result.t} | {:error, Postgrex.Error.t}
  def execute(conn, query, params, opts) do
    # use sbroker as the default pool
    opts = Keyword.put_new(opts, :pool, DBConnection.Sojourn)
    # use :null as the default null value, instead of nil
    opts = Keyword.put_new(opts, :null, :null)

    Postgrex.execute(conn, query, params, opts)
  end

  def execute(conn, query, params), do: execute(conn, query, params, [])


  @doc """
  closes an (extended) prepared query and returns `ok` or `{error, Error`}
  if there was an error. closing a query releases any resources held by
  postgresql for a prepared query with that name
  
  ## options

    * `pool_timeout` - time to wait in the queue for the connection
    (default: `#{@pool_timeout}`)
    * `queue` - whether to wait for connection in a queue (default: `true`);
    * `timeout` - query request timeout (default: `#{@timeout}`);
    * `pool` - the pool module to use, must match that set on `start_link/1`
    (default: `'Elixir.DBConnection.Sojourn'`);
    * `mode` - set to `savepoint` to use a savepoint to rollback to before the
    query on error, otherwise set to `transaction` (default: `transaction`);

  ## examples

      {ok, Query} = posterize:prepare(Conn, "", "CREATE TABLE posts (id serial, title text)"),
      ok = posterize:close(Conn, Query).
  """
  @spec close(conn, Postgrex.Query.t, Keyword.t) :: :ok | {:error, Postgrex.Error.t}
  def close(conn, query, opts) do
    # use sbroker as the default pool
    opts = Keyword.put_new(opts, :pool, DBConnection.Sojourn)

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
  
    * `pool_timeout` - time to wait in the queue for the connection
    (default: `#{@pool_timeout}`)
    * `queue` - whether to wait for connection in a queue (default: `true`);
    * `timeout` - transaction timeout (default: `#{@timeout}`);
    * `pool` - the pool module to use, must match that set on `start_link/1`
    (default: `'Elixir.DBConnection.Sojourn'`);
    * `mode` - set to `savepoint` to use a savepoint to rollback to before the
    query on error, otherwise set to `transaction` (default: `transaction`);
  
  the `timeout` is for the duration of the transaction and all nested
  transactions and requests. this timeout overrides timeouts set by internal
  transactions and requests. the `pool` and `mode` will be used for all
  requests inside the transaction function
  
  ## example

      Fun = fun(Conn) -> posterize:query(Conn, "", "SELECT title FROM posts", []) end,
      {ok, Result} = posterize:transaction(Conn, Fun).
  """
  @spec transaction(conn, ((DBConnection.t) -> result), Keyword.t) ::
    {:ok, result} | {:error, any} when result: var
  def transaction(conn, fun, opts) do
    # use sbroker as the default pool
    opts = Keyword.put_new(opts, :pool, DBConnection.Sojourn)

    Postgrex.transaction(conn, fun, opts)
  end

  def transaction(conn, fun), do: transaction(conn, fun, [])


  @doc """
  rollback a transaction, does not return

  aborts the current transaction fun. if inside multiple `transaction/3`
  functions, bubbles up to the top level
  
  ## example
      {error, oops} = posterize:transaction(Conn, fun(Conn) ->
        posterize:rollback(Conn, bar),
        io:format("never reaches here!~n", [])
      end).
  """
  @spec rollback(DBConnection.t, any) :: no_return()
  defdelegate rollback(conn, any), to: DBConnection


  @doc """
  returns a cached map of connection parameters.

  ## options

    * `timeout` - Call timeout (default: `#{@timeout}`)
    * `pool` - the pool module to use, must match that set on `start_link/1`
    (default: `'Elixir.DBConnection.Sojourn'`);
  """
  @spec parameters(pid, Keyword.t) :: map
  def parameters(pid, opts \\ []) do
    # use sbroker as the default pool
    opts = Keyword.put_new(opts, :pool, DBConnection.Sojourn)

    Postgrex.parameters(pid, opts)
  end
end