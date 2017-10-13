defmodule Posterize.Extensions.TimeTz.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp encode(units, time, offset) do
    :posterize_xt_timetz.do_encode(units, time, offset)
  end

  defp encode(time, offset) do
    :posterize_xt_timetz.do_encode(:native, time, offset)
  end

  test "0" do
    assert <<12::int32, 0::int64, 0::int32>> == encode(0, 0)
  end

  test "1 nanosecond" do
    assert <<12::int32, 0::int64, 0::int32>> == encode(:nano_seconds, 1, 0)
  end

  test "-1 nanosecond" do
    assert <<12::int32, -1::int64, 0::int32>> == encode(:nano_seconds, -1, 0)
  end

  test "1 microsecond" do
    assert <<12::int32, 1::int64, 0::int32>> == encode(:micro_seconds, 1, 0)
  end

  test "-1 microsecond" do
    assert <<12::int32, -1::int64, 0::int32>> == encode(:micro_seconds, -1, 0)
  end

  test "1 millisecond" do
    assert <<12::int32, 1000::int64, 0::int32>> == encode(:milli_seconds, 1, 0)
  end

  test "-1 millisecond" do
    assert <<12::int32, -1000::int64, 0::int32>> == encode(:milli_seconds, -1, 0)
  end

  test "1 second" do
    assert <<12::int32, 1_000_000::int64, 0::int32>> == encode(:seconds, 1, 0)
  end

  test "-1 second" do
    assert <<12::int32, -1_000_000::int64, 0::int32>> == encode(:seconds, -1, 0)
  end

  test "1 second in nanoseconds" do
    assert <<12::int32, 1_000_000::int64, 0::int32>> ==
             encode(:nano_seconds, :erlang.convert_time_unit(1, :seconds, :nano_seconds), 0)
  end

  test "1 second in microseconds" do
    assert <<12::int32, 1_000_000::int64, 0::int32>> ==
             encode(:micro_seconds, :erlang.convert_time_unit(1, :seconds, :micro_seconds), 0)
  end

  test "1 second in milliseconds" do
    assert <<12::int32, 1_000_000::int64, 0::int32>> ==
             encode(:milli_seconds, :erlang.convert_time_unit(1, :seconds, :milli_seconds), 0)
  end

  test "1 second in seconds" do
    assert <<12::int32, 1_000_000::int64, 0::int32>> == encode(:seconds, 1, 0)
  end

  test "1 second in native units" do
    assert <<12::int32, 1_000_000::int64, 0::int32>> ==
             encode(:erlang.convert_time_unit(1, :seconds, :native), 0)
  end

  test "1 minute in native units" do
    assert <<12::int32, 60_000_000::int64, 0::int32>> ==
             encode(:erlang.convert_time_unit(60, :seconds, :native), 0)
  end

  test "1 hour in native units" do
    assert <<12::int32, 3_600_000_000::int64, 0::int32>> ==
             encode(:erlang.convert_time_unit(60 * 60, :seconds, :native), 0)
  end

  test "1 hour 1 minute 1 second in native units" do
    assert <<12::int32, 3_661_000_000::int64, 0::int32>> ==
             encode(:erlang.convert_time_unit(60 * 60 + 61, :seconds, :native), 0)
  end

  test "23 hours, 59 minutes and 59 seconds in seconds" do
    assert <<12::int32, 86_399_000_000::int64, 0::int32>> == encode(:seconds, 86399, 0)
  end

  test "1 second with -0001 offset" do
    assert <<12::int32, 1_000_000::int64, 60::int32>> == encode(:seconds, 1, 60)
  end

  test "1 second with +0001 offset" do
    assert <<12::int32, 1_000_000::int64, -60::int32>> == encode(:seconds, 1, -60)
  end
end

defmodule Posterize.Extensions.TimeTz.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp decode(units, time, offset) do
    :posterize_xt_timetz.do_decode(units, time, offset)
  end

  defp decode(time, offset) do
    :posterize_xt_timetz.do_decode(:native, time, offset)
  end

  test "0" do
    assert {0, 0} == decode(0, 0)
  end

  test "1 microsecond" do
    assert {1, 0} == decode(:micro_seconds, 1, 0)
  end

  test "-1 microsecond" do
    assert {-1, 0} == decode(:micro_seconds, -1, 0)
  end

  test "1 millisecond" do
    assert {1, 0} == decode(:milli_seconds, 1000, 0)
  end

  test "-1 millisecond" do
    assert {-1, 0} == decode(:milli_seconds, -1000, 0)
  end

  test "1 second" do
    assert {1, 0} == decode(:seconds, 1_000_000, 0)
  end

  test "-1 second" do
    assert {-1, 0} == decode(:seconds, -1_000_000, 0)
  end

  test "1 second in native units" do
    time = :erlang.convert_time_unit(1, :seconds, :native)
    assert {time, 0} == decode(1_000_000, 0)
  end

  test "-1 second in native units" do
    time = :erlang.convert_time_unit(-1, :seconds, :native)
    assert {time, 0} == decode(-1_000_000, 0)
  end

  test "1 minute in native units" do
    time = :erlang.convert_time_unit(60, :seconds, :native)
    assert {time, 0} == decode(60_000_000, 0)
  end

  test "1 hour in native units" do
    time = :erlang.convert_time_unit(3600, :seconds, :native)
    assert {time, 0} == decode(3_600_000_000, 0)
  end

  test "23 hours 59 minutes 59 seconds in native units" do
    time = :erlang.convert_time_unit(86399, :seconds, :native)
    assert {time, 0} == decode(86_399_000_000, 0)
  end

  test "1 second with -0001 offset" do
    assert {1, 60} == decode(:seconds, 1_000_000, 60)
  end

  test "1 second with -0001 offset in native units" do
    time = :erlang.convert_time_unit(1, :seconds, :native)
    offset = :erlang.convert_time_unit(60, :seconds, :native)
    assert {time, offset} == decode(1_000_000, 60)
  end

  test "1 second with +0001 offset" do
    assert {1, -60} == decode(:seconds, 1_000_000, -60)
  end

  test "1 second with +0001 offset in native units" do
    time = :erlang.convert_time_unit(1, :seconds, :native)
    offset = :erlang.convert_time_unit(60, :seconds, :native) * -1
    assert {time, offset} == decode(1_000_000, -60)
  end
end
