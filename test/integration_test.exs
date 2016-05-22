defmodule QueryTest do
  use ExUnit.Case, async: true
  import Postgrex.TestHelper
  
  @moduletag :integration

  setup do
    opts = [ database: "postgrex_test", backoff_type: :stop ]
    {:ok, pid} = :posterize.start_link(opts)
    {:ok, [pid: pid]}
  end

  test "decode basic types", context do
    assert [[nil]] = query("SELECT NULL", [])
    assert [[true, false]] = query("SELECT true, false", [])
    assert [["e"]] = query("SELECT 'e'::char", [])
    assert [["ẽ"]] = query("SELECT 'ẽ'::char", [])
    assert [[42]] = query("SELECT 42", [])
    assert [[42.0]] = query("SELECT 42::float", [])
    assert [[:NaN]] = query("SELECT 'NaN'::float", [])
    assert [[:inf]] = query("SELECT 'inf'::float", [])
    assert [[:"-inf"]] = query("SELECT '-inf'::float", [])
    assert [["ẽric"]] = query("SELECT 'ẽric'", [])
    assert [["ẽric"]] = query("SELECT 'ẽric'::varchar", [])
    assert [[<<1, 2, 3>>]] = query("SELECT '\\001\\002\\003'::bytea", [])
  end

  test "encode basic types", context do
    assert [[nil, nil]] = query("SELECT $1::text, $2::int", [nil, nil])
    assert [[true, false]] = query("SELECT $1::bool, $2::bool", [true, false])
    assert [["ẽ"]] = query("SELECT $1::char", ["ẽ"])
    assert [[42]] = query("SELECT $1::int", [42])
    assert [[42.0, 43.0]] = query("SELECT $1::float, $2::float", [42, 43.0])
    assert [[:NaN]] = query("SELECT $1::float", [:NaN])
    assert [[:inf]] = query("SELECT $1::float", [:inf])
    assert [[:"-inf"]] = query("SELECT $1::float", [:"-inf"])
    assert [["ẽric"]] = query("SELECT $1::varchar", ["ẽric"])
    assert [[<<1, 2, 3>>]] = query("SELECT $1::bytea", [<<1, 2, 3>>])
  end

  test "decode datetime types", context do
    assert [[{1979, 6, 21}]] = query("SELECT '1979-06-21'::date", [])
    assert [[{15, 3, 48}]] = query("SELECT '15:03:48'::time", [])
    assert [[{{1979, 6, 21}, {15, 3, 48}}]] = query("SELECT '1979-06-21T15:03:48'::timestamp", [])
    assert [[{{15, 3, 48}, 15, 7}]] = query("SELECT '7 months 15 days 15 hours 3 minutes 48 seconds'::interval", [])
  end

  test "encode datetime types", context do
    assert [[{1979, 6, 21}]] = query("SELECT $1::date", [{1979, 6, 21}])
    assert [[{15, 3, 48}]] = query("SELECT $1::time", [{15, 3, 48}])
    assert [[{{1979, 6, 21}, {15, 3, 48}}]] = query("SELECT $1::timestamp", [{{1979, 6, 21}, {15, 3, 48}}])
    assert [[{{15, 3, 48}, 15, 7}]] = query("SELECT $1::interval", [{{15, 3, 48}, 15, 7}])
  end
end

defmodule PrepareTest do
  use ExUnit.Case, async: true
  import Postgrex.TestHelper

  @moduletag :integration

  setup do
    opts = [ database: "postgrex_test", backoff_type: :stop ]
    {:ok, pid} = :posterize.start_link(opts)
    {:ok, [pid: pid]}
  end

  test "prepare and execute a query", context do
    assert (%Postgrex.Query{} = query) = prepare("prepared_statement", "SELECT $1::text")
    assert [["hallo world"]] = execute(query, ["hallo world"])
    assert [["hallo to me"]] = execute(query, ["hallo to me"])
  end
end

defmodule CloseTest do
  use ExUnit.Case, async: true
  import Postgrex.TestHelper

  @moduletag :integration

  setup do
    opts = [ database: "postgrex_test", backoff_type: :stop ]
    {:ok, pid} = :posterize.start_link(opts)
    {:ok, [pid: pid]}
  end

  test "close a query after preparing and executing", context do
    assert (%Postgrex.Query{} = query) = prepare("prepared_statement", "SELECT $1::text")
    assert [["hallo world"]] = execute(query, ["hallo world"])
    assert :ok = close(query)
  end
end

defmodule TransactionTest do
  use ExUnit.Case, async: true
  import Postgrex.TestHelper

  @moduletag :integration

  setup do
    opts = [ database: "postgrex_test", backoff_type: :stop ]
    {:ok, pid} = :posterize.start_link(opts)
    {:ok, [pid: pid]}
  end

  test "run a query in a transaction", context do
      query = fn(conn) ->
        {:ok, res} = :posterize.query(conn, "SELECT true", [])
        res.rows
      end
      assert {:ok, [[true]]} = transaction(query)
  end
end

defmodule UserExtensionTest do
  use ExUnit.Case, async: true
  import Postgrex.TestHelper

  @moduletag :integration

  setup do
    opts = [ database: "postgrex_test", backoff_type: :stop ]
    {:ok, pid} = :posterize.start_link([extensions: [{:posterize_xt_jsx, []}] ++ :posterize_xt_integer_utils.stack] ++ opts)
    {:ok, [pid: pid]}
  end

  @tag min_pg_version: "9.4"
  test "user specified extensions are used for decoding", context do
    units = :erlang.convert_time_unit((15 * 3600) + (3 * 60) + 48, :seconds, :native)
    assert [[units]] == query("SELECT '15:03:48'::time", [])
    assert [[%{"key" => "value"}]] == query("SELECT '{\"key\":\"value\"}'::json", [])
  end

  @tag min_pg_version: "9.4"
  test "user specified extensions are used for encoding", context do
    units = :erlang.convert_time_unit((15 * 3600) + (3 * 60) + 48, :seconds, :native)
    assert [[units]] == query("SELECT $1::time", [units])
    assert [[%{"key" => "value"}]] == query("SELECT $1::json", [%{"key" => "value"}])
  end
end

defmodule Posterize.Integration.Integer.Time.Test do
  use ExUnit.Case, async: true
  import Postgrex.TestHelper

  @moduletag :integration

  setup do
    opts = [ database: "postgrex_test", backoff_type: :stop ]
    {:ok, pid} = :posterize.start_link([extensions: :posterize_xt_integer_utils.stack] ++ opts)
    {:ok, [pid: pid]}
  end

  test "decode datetime types", context do
    units = :erlang.convert_time_unit(298771200000000, :micro_seconds, :native)
    assert [[units]] == query("SELECT '1979-06-21'::date", [])
    units = :erlang.convert_time_unit((15 * 3600) + (3 * 60) + 48, :seconds, :native)
    assert [[units]] == query("SELECT '15:03:48'::time", [])
    units = :erlang.convert_time_unit(298771200000000 + (15 * 3600000000) + (3 * 60000000) + 48000000, :micro_seconds, :native)
    assert [[units]] == query("SELECT '1979-06-21T15:03:48Z'::timestamp", [])
    units = :erlang.convert_time_unit((15 * 3600) + (3 * 60) + 48, :seconds, :native)
    assert [[units]] == query("SELECT '15 hours 3 minutes 48 seconds'::interval", [])
  end

  test "encode datetime types", context do
    units = :erlang.convert_time_unit(298771200000000, :micro_seconds, :native)
    assert [[units]] == query("SELECT $1::date", [units])
    units = :erlang.convert_time_unit((15 * 3600) + (3 * 60) + 48, :seconds, :native)
    assert [[units]] == query("SELECT $1::time", [units])
    units = :erlang.convert_time_unit(298771200000000 + (15 * 3600000000) + (3 * 60000000) + 48000000, :micro_seconds, :native)
    assert [[units]] == query("SELECT $1::timestamp", [units])
    units = :erlang.convert_time_unit((15 * 3600) + (3 * 60) + 48, :seconds, :native)
    assert [[units]] == query("SELECT $1::interval", [units])
  end
end


defmodule Posterize.Integration.JSON.Test do
  use ExUnit.Case, async: true
  import Postgrex.TestHelper

  @moduletag :integration

  setup do
    opts = [ database: "postgrex_test", backoff_type: :stop ]
    {:ok, pid} = :posterize.start_link([extensions: [{:posterize_xt_jsx, []}]] ++ opts)
    {:ok, [pid: pid]}
  end

  @tag min_pg_version: "9.4"
  test "decode json types", context do
    assert [[true]] == query("SELECT 'true'::json", [])
    assert [[1]] == query("SELECT '1'::json", [])
    assert [[1.0]] == query("SELECT '1.0'::json", [])
    assert [["hallo world"]] == query("SELECT '\"hallo world\"'::json", [])
    assert [[%{"key" => "value"}]] == query("SELECT '{\"key\":\"value\"}'::json", [])
    assert [[[true, 1, 1.0, "hallo world"]]] == query("SELECT '[true, 1, 1.0, \"hallo world\"]'::json", [])
  end

  @tag min_pg_version: "9.4"
  test "encode json types", context do
    assert [[true]] == query("SELECT $1::json", [true])
    assert [[1]] == query("SELECT $1::json", [1])
    assert [[1.0]] == query("SELECT $1::json", [1.0])
    assert [["hallo world"]] == query("SELECT $1::json", ["hallo world"])
    assert [[%{"key" => "value"}]] == query("SELECT $1::json", [%{"key" => "value"}])
    assert [[[true, 1, 1.0, "hallo world"]]] == query("SELECT $1::json", [[true, 1, 1.0, "hallo world"]])
  end

  @tag min_pg_version: "9.4"
  test "decode jsonb types", context do
    assert [[true]] == query("SELECT 'true'::jsonb", [])
    assert [[1]] == query("SELECT '1'::jsonb", [])
    assert [[1.0]] == query("SELECT '1.0'::jsonb", [])
    assert [["hallo world"]] == query("SELECT '\"hallo world\"'::jsonb", [])
    assert [[%{"key" => "value"}]] == query("SELECT '{\"key\":\"value\"}'::jsonb", [])
    assert [[[true, 1, 1.0, "hallo world"]]] == query("SELECT '[true, 1, 1.0, \"hallo world\"]'::jsonb", [])
  end

  @tag min_pg_version: "9.4"
  test "encode jsonb types", context do
    assert [[true]] == query("SELECT $1::jsonb", [true])
    assert [[1]] == query("SELECT $1::jsonb", [1])
    assert [[1.0]] == query("SELECT $1::jsonb", [1.0])
    assert [["hallo world"]] == query("SELECT $1::jsonb", ["hallo world"])
    assert [[%{"key" => "value"}]] == query("SELECT $1::jsonb", [%{"key" => "value"}])
    assert [[[true, 1, 1.0, "hallo world"]]] == query("SELECT $1::jsonb", [[true, 1, 1.0, "hallo world"]])
  end
end
