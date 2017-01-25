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
    assert [[:null]] = query("SELECT NULL", [])
    assert [[true, false]] = query("SELECT true, false", [])
    assert [["e"]] = query("SELECT 'e'::char", [])
    assert [["ẽ"]] = query("SELECT 'ẽ'::char", [])
    assert [[42]] = query("SELECT 42", [])
    assert [[42.0]] = query("SELECT 42::float", [])
    assert [[:NaN]] = query("SELECT 'NaN'::float", [])
    assert [[:infinity]] = query("SELECT 'infinity'::float", [])
    assert [[:'-infinity']] = query("SELECT '-infinity'::float", [])
    assert [["ẽric"]] = query("SELECT 'ẽric'", [])
    assert [["ẽric"]] = query("SELECT 'ẽric'::varchar", [])
    assert [[<<1, 2, 3>>]] = query("SELECT '\\001\\002\\003'::bytea", [])
  end

  test "encode basic types", context do
    assert [[:null, :null]] = query("SELECT $1::text, $2::int", [:null, :null])
    assert [[true, false]] = query("SELECT $1::bool, $2::bool", [true, false])
    assert [["ẽ"]] = query("SELECT $1::char", ["ẽ"])
    assert [[42]] = query("SELECT $1::int", [42])
    assert [[42.0, 43.0]] = query("SELECT $1::float, $2::float", [42, 43.0])
    assert [[:NaN]] = query("SELECT $1::float", [:NaN])
    assert [[:infinity]] = query("SELECT $1::float", [:infinity])
    assert [[:'-infinity']] = query("SELECT $1::float", [:'-infinity'])
    assert [["ẽric"]] = query("SELECT $1::varchar", ["ẽric"])
    assert [[<<1, 2, 3>>]] = query("SELECT $1::bytea", [<<1, 2, 3>>])
  end

  test "decode date types", context do
    assert [[{ -4713, 1, 1 }]] = query("SELECT 'Jan 1, 4713 BC'::date", [])
    assert [[{ -4713, 2, 29 }]] = query("SELECT 'Feb 29, 4713 BC'::date", [])
    assert [[{ -401, 2, 29 }]] = query("SELECT 'Feb 29, 401 BC'::date", [])
    assert [[{ -1, 2, 29 }]] = query("SELECT 'Feb 29, 1 BC'::date", [])
    assert [[{ 400, 2, 29 }]] = query("SELECT 'Feb 29, 400'::date", [])
    assert [[{ 1979, 6, 21 }]] = query("SELECT '1979-06-21'::date", [])
  end

  test "encode date types", context do
    assert [[{ -4713, 1, 1 }]] = query("SELECT $1::date", [{ -4713, 1, 1 }])
    assert [[{ -4713, 2, 29 }]] = query("SELECT $1::date", [{ -4713, 2, 29 }])
    assert [[{ -401, 2, 29 }]] = query("SELECT $1::date", [{ -401, 2, 29 }])
    assert [[{ -1, 2, 29 }]] = query("SELECT $1::date", [{ -1, 2, 29 }])
    assert [[{ 400, 2, 29 }]] = query("SELECT $1::date", [{ 400, 2, 29 }])
    assert [[{ 1979, 6, 21 }]] = query("SELECT $1::date", [{ 1979, 6, 21 }])
  end

  test "decode time + timestamp types", context do
    units = :erlang.convert_time_unit((15 * 3600) + (3 * 60) + 48, :seconds, :native)
    assert [[units]] == query("SELECT '15:03:48'::time", [])
    pos_offset = :erlang.convert_time_unit(-60, :seconds, :native)
    neg_offset = :erlang.convert_time_unit(60, :seconds, :native)
    assert [[{ units, 0 }]] == query("SELECT '15:03:48-00:00'::timetz", [])
    assert [[{ units, pos_offset }]] == query("SELECT '15:03:48+00:01'::timetz", [])
    assert [[{ units, neg_offset }]] == query("SELECT '15:03:48-00:01'::timetz", [])
    units = :erlang.convert_time_unit(298771200000000 + (15 * 3600000000) + (3 * 60000000) + 48000000, :micro_seconds, :native)
    assert [[units]] == query("SELECT '1979-06-21T15:03:48Z'::timestamp", [])
    assert [[units]] == query("SELECT '1979-06-21T15:03:48-00:00'::timestamptz", [])
    assert [[units + pos_offset]] == query("SELECT '1979-06-21T15:03:48+00:01'::timestamptz", [])
    assert [[units + neg_offset]] == query("SELECT '1979-06-21T15:03:48-00:01'::timestamptz", [])
    assert [[:infinity]] == query("SELECT 'infinity'::timestamp", [])
    assert [[:infinity]] == query("SELECT 'infinity'::timestamptz", [])
    assert [[:'-infinity']] == query("SELECT '-infinity'::timestamp", [])
    assert [[:'-infinity']] == query("SELECT '-infinity'::timestamptz", [])
  end

  test "encode time + timestamp types", context do
    units = :erlang.convert_time_unit((15 * 3600) + (3 * 60) + 48, :seconds, :native)
    assert [[units]] == query("SELECT $1::time", [units])
    units = :erlang.convert_time_unit((15 * 3600) + (3 * 60) + 48, :seconds, :native)
    pos_offset = :erlang.convert_time_unit(60, :seconds, :native)
    neg_offset = :erlang.convert_time_unit(-60, :seconds, :native)
    assert [[{ units, 0 }]] == query("SELECT $1::timetz", [units])
    assert [[{ units, 0 }]] == query("SELECT $1::timetz", [{ units, 0 }])
    assert [[{ units, pos_offset }]] == query("SELECT $1::timetz", [{ units, pos_offset }])
    assert [[{ units, neg_offset }]] == query("SELECT $1::timetz", [{ units, neg_offset }])
    units = :erlang.convert_time_unit(298771200000000 + (15 * 3600000000) + (3 * 60000000) + 48000000, :micro_seconds, :native)
    assert [[units]] == query("SELECT $1::timestamp", [units])
    assert [[units]] == query("SELECT $1::timestamptz", [units])
    assert [[:infinity]] == query("SELECT $1::timestamp", [:infinity])
    assert [[:infinity]] == query("SELECT $1::timestamptz", [:infinity])
    assert [[:'-infinity']] == query("SELECT $1::timestamp", [:'-infinity'])
    assert [[:'-infinity']] == query("SELECT $1::timestamptz", [:'-infinity'])
  end

  test "encode intervals", context do
    assert [[%{ microseconds: 0 }]] == query("SELECT $1::interval", [%{ microseconds: 0 }])
    assert [[%{ months: 1, days: 1, microseconds: 1 }]] == query("SELECT $1::interval", [%{ months: 1, days: 1, microseconds: 1 }])
    assert [[%{ months: 12, days: 7, microseconds: 0 }]] == query("SELECT $1::interval", [%{ years: 1, weeks: 1, microseconds: 0 }])
    assert [[%{ months: 13, days: 8, microseconds: 3661000000 }]] == query("SELECT $1::interval", [%{ years: 1, months: 1, weeks: 1, days: 1, hours: 1, minutes: 1, seconds: 1 }])
  end

  test "decode intervals", context do
    assert [[%{ microseconds: 0 }]] == query("SELECT '0 seconds'::interval", [])
    assert [[%{ months: 1, days: 1, microseconds: 1 }]] == query("SELECT '1 month 1 day 0.000001 seconds'::interval", [])
    assert [[%{ months: 12, days: 7, microseconds: 0 }]] == query("SELECT '1 year 1 week'::interval", [])
    assert [[%{ months: 13, days: 8, microseconds: 3661000000 }]] == query("SELECT '1 year 1 month 1 week 1 day 1 hour 1 minute 1 second'::interval", [])
  end

  @tag min_pg_version: "9.2"
  test "encode ranges", context do
    assert [[:empty]] == query("SELECT $1::int4range", [%{ lower: 1, upper: 1, bounds: :'[)' }])
    assert [[%{ bounds: :'()' }]] == query("SELECT $1::int4range", [%{ bounds: :'()' }])
    assert [[%{ lower: 1, upper: 3, bounds: :'[)' }]] == query("SELECT $1::int4range", [%{ lower: 1, upper: 3, bounds: :'[)' }])
    assert [[%{ lower: 1, upper: 3, bounds: :'[)' }]] == query("SELECT $1::int4range", [%{ lower: 1, upper: 2, bounds: :'[]' }])
    assert [[%{ lower: 2, bounds: :'[)' }]] == query("SELECT $1::int4range", [%{ lower: 1, bounds: :'()' }])
    assert [[%{ upper: 10, bounds: :'()' }]] == query("SELECT $1::int4range", [%{ upper: 10, bounds: :'()' }])
    assert [[%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'[]' }]] == query("SELECT $1::tsrange", [%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'[]' }])
    assert [[%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'(]' }]] == query("SELECT $1::tsrange", [%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'(]' }])
    assert [[%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'[)' }]] == query("SELECT $1::tsrange", [%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'[)' }])
    assert [[%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'()' }]] == query("SELECT $1::tsrange", [%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'()' }])
  end

  @tag min_pg_version: "9.2"
  test "decode ranges", context do
    assert [[:empty]] == query("SELECT '[1,1)'::int4range", [])
    assert [[%{ lower: 1, upper: 3, bounds: :'[)' }]] == query("SELECT '[1,3)'::int4range", [])
    assert [[%{ lower: 1, upper: 3, bounds: :'[)' }]] == query("SELECT '[1,2]'::int4range", [])
    assert [[%{ upper: 3, bounds: :'()' }]] == query("SELECT '(,2]'::int4range", [])
    assert [[%{ lower: 1, bounds: :'[)' }]] == query("SELECT '[1,)'::int4range", [])
    assert [[%{ bounds: :'()' }]] == query("SELECT '(,)'::int4range", [])
    assert [[%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'[]' }]] == query("SELECT '[2000-01-01,2001-01-01]'::tsrange", [])
    assert [[%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'(]' }]] == query("SELECT '(2000-01-01,2001-01-01]'::tsrange", [])
    assert [[%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'[)' }]] == query("SELECT '[2000-01-01,2001-01-01)'::tsrange", [])
    assert [[%{ lower: 946684800000000000, upper: 978307200000000000, bounds: :'()' }]] == query("SELECT '(2000-01-01,2001-01-01)'::tsrange", [])
  end

  @tag min_pg_version: "9.4"
  test "decode json types", context do
    assert [["true"]] == query("SELECT 'true'::json", [])
    assert [["1"]] == query("SELECT '1'::json", [])
    assert [["1.0"]] == query("SELECT '1.0'::json", [])
    assert [["\"hallo world\""]] == query("SELECT '\"hallo world\"'::json", [])
    assert [["{\"key\":\"value\"}"]] == query("SELECT '{\"key\":\"value\"}'::json", [])
    assert [["[true,1,1.0,\"hallo world\"]"]] == query("SELECT '[true,1,1.0,\"hallo world\"]'::json", [])
  end

  @tag min_pg_version: "9.4"
  test "encode json types", context do
    assert [["true"]] == query("SELECT $1::json", ["true"])
    assert [["1"]] == query("SELECT $1::json", ["1"])
    assert [["1.0"]] == query("SELECT $1::json", ["1.0"])
    assert [["\"hallo world\""]] == query("SELECT $1::json", ["\"hallo world\""])
    assert [["{\"key\":\"value\"}"]] == query("SELECT $1::json", ["{\"key\":\"value\"}"])
    assert [["[true,1,1.0,\"hallo world\"]"]] == query("SELECT $1::json", ["[true,1,1.0,\"hallo world\"]"])
  end

  @tag min_pg_version: "9.4"
  test "decode jsonb types", context do
    assert [["true"]] == query("SELECT 'true'::jsonb", [])
    assert [["1"]] == query("SELECT '1'::jsonb", [])
    assert [["1.0"]] == query("SELECT '1.0'::jsonb", [])
    assert [["\"hallo world\""]] == query("SELECT '\"hallo world\"'::jsonb", [])
    assert [["{\"key\": \"value\"}"]] == query("SELECT '{\"key\":\"value\"}'::jsonb", [])
    assert [["[true, 1, 1.0, \"hallo world\"]"]] == query("SELECT '[true,1,1.0,\"hallo world\"]'::jsonb", [])
  end

  @tag min_pg_version: "9.4"
  test "encode jsonb types", context do
    assert [["true"]] == query("SELECT $1::jsonb", ["true"])
    assert [["1"]] == query("SELECT $1::jsonb", ["1"])
    assert [["1.0"]] == query("SELECT $1::jsonb", ["1.0"])
    assert [["\"hallo world\""]] == query("SELECT $1::jsonb", ["\"hallo world\""])
    assert [["{\"key\": \"value\"}"]] == query("SELECT $1::jsonb", ["{\"key\":\"value\"}"])
    assert [["[true, 1, 1.0, \"hallo world\"]"]] == query("SELECT $1::jsonb", ["[true,1,1.0,\"hallo world\"]"])
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
