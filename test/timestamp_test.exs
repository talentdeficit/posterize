defmodule Posterize.Extensions.Timestamp.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp encode(units, count) do
    :posterize_xt_timestamp.do_encode(units, count)
  end

  defp encode(count) do
    :posterize_xt_timestamp.do_encode(:native, count)
  end

  test "infinity" do
    assert <<8::int32, 9_223_372_036_854_775_807::int64>> == encode(:infinity)
  end

  test "-infinity" do
    assert <<8::int32, -9_223_372_036_854_775_808::int64>> == encode(:"-infinity")
  end

  test "1999-12-31T23:59:59 in nanoseconds" do
    assert <<8::int32, -1_000_000::int64>> == encode(:nano_seconds, 946_684_799_000_000_000)
  end

  test "1999-12-31T23:59:59 in microseconds" do
    assert <<8::int32, -1_000_000::int64>> == encode(:micro_seconds, 946_684_799_000_000)
  end

  test "1999-12-31T23:59:59 in milliseconds" do
    assert <<8::int32, -1_000_000::int64>> == encode(:milli_seconds, 946_684_799_000)
  end

  test "1999-12-31T23:59:59 in seconds" do
    assert <<8::int32, -1_000_000::int64>> == encode(:seconds, 946_684_799)
  end

  test "1999-12-31T23:59:59 in native units" do
    assert <<8::int32, -1_000_000::int64>> ==
             encode(:erlang.convert_time_unit(946_684_799, :seconds, :native))
  end

  test "2000-01-01T00:00:00 in microseconds" do
    assert <<8::int32, 0::int64>> == encode(:micro_seconds, 946_684_800_000_000)
  end

  test "2000-01-01T00:00:01 in microseconds" do
    assert <<8::int32, 1_000_000::int64>> == encode(:micro_seconds, 946_684_801_000_000)
  end

  test "2016-02-03T07:32:45 in microseconds" do
    assert <<8::int32, 507_799_965_000_000::int64>> ==
             encode(:micro_seconds, 1_454_484_765_000_000)
  end
end

defmodule Posterize.Extensions.Timestamp.Decode.Test do
  use ExUnit.Case

  defp decode(units, timestamp) do
    :posterize_xt_timestamp.do_decode(units, timestamp)
  end

  defp decode(timestamp) do
    :posterize_xt_timestamp.do_decode(:native, timestamp)
  end

  test "infinity" do
    assert :infinity == decode(9_223_372_036_854_775_807)
  end

  test "-infinity" do
    assert :"-infinity" == decode(-9_223_372_036_854_775_808)
  end

  test "1979-06-21T15:32:14 in nano seconds" do
    units = :erlang.convert_time_unit(298_827_134, :seconds, :nano_seconds)
    assert units == decode(:nano_seconds, -647_857_666_000_000)
  end

  test "1979-06-21T15:32:14 in micro_seconds" do
    units = :erlang.convert_time_unit(298_827_134, :seconds, :micro_seconds)
    assert units == decode(:micro_seconds, -647_857_666_000_000)
  end

  test "1979-06-21T15:32:14 in milli_seconds" do
    units = :erlang.convert_time_unit(298_827_134, :seconds, :milli_seconds)
    assert units == decode(:milli_seconds, -647_857_666_000_000)
  end

  test "1979-06-21T15:32:14 in seconds" do
    units = :erlang.convert_time_unit(298_827_134, :seconds, :seconds)
    assert units == decode(:seconds, -647_857_666_000_000)
  end

  test "1979-06-21T15:32:14 in native units" do
    units = :erlang.convert_time_unit(298_827_134, :seconds, :native)
    assert units == decode(-647_857_666_000_000)
  end

  test "1999-12-31T23:59:59 in native units" do
    units = :erlang.convert_time_unit(946_684_799, :seconds, :native)
    assert units == decode(-1_000_000)
  end

  test "2000-01-01T00:00:00 in native units" do
    units = :erlang.convert_time_unit(946_684_800, :seconds, :native)
    assert units == decode(0)
  end

  test "2000-01-01T00:00:01 in native units" do
    units = :erlang.convert_time_unit(946_684_801, :seconds, :native)
    assert units == decode(1_000_000)
  end

  test "2016-02-03T07:32:45 in native units" do
    units = :erlang.convert_time_unit(1_454_484_765, :seconds, :native)
    assert units == decode(507_799_965_000_000)
  end
end
