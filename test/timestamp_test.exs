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
    assert << 8 :: int32, 9223372036854775807 :: int64 >> == encode(:infinity)
  end

  test "-infinity" do
    assert << 8 :: int32, -9223372036854775808 :: int64 >> == encode(:'-infinity')
  end

  test "1999-12-31T23:59:59 in nanoseconds" do
    assert << 8 :: int32, -1000000 :: int64 >> == encode(:nano_seconds, 946684799000000000)
  end

  test "1999-12-31T23:59:59 in microseconds" do
    assert << 8 :: int32, -1000000 :: int64 >> == encode(:micro_seconds, 946684799000000)
  end

  test "1999-12-31T23:59:59 in milliseconds" do
    assert << 8 :: int32, -1000000 :: int64 >> == encode(:milli_seconds, 946684799000)
  end

  test "1999-12-31T23:59:59 in seconds" do
    assert << 8 :: int32, -1000000 :: int64 >> == encode(:seconds, 946684799)
  end

  test "1999-12-31T23:59:59 in native units" do
    assert << 8 :: int32, -1000000 :: int64 >> == encode(:erlang.convert_time_unit(946684799, :seconds, :native))
  end

  test "2000-01-01T00:00:00 in microseconds" do
    assert << 8 :: int32, 0 :: int64 >> == encode(:micro_seconds, 946684800000000)
  end

  test "2000-01-01T00:00:01 in microseconds" do
    assert << 8 :: int32, 1000000 :: int64 >> == encode(:micro_seconds, 946684801000000)
  end

  test "2016-02-03T07:32:45 in microseconds" do
    assert << 8 :: int32, 507799965000000 :: int64 >> == encode(:micro_seconds, 1454484765000000)
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
    assert :infinity == decode(9223372036854775807)
  end

  test "-infinity" do
    assert :'-infinity' == decode(-9223372036854775808)
  end

  test "1979-06-21T15:32:14 in nano seconds" do
    units = :erlang.convert_time_unit(298827134, :seconds, :nano_seconds)
    assert units == decode(:nano_seconds, -647857666000000)
  end

  test "1979-06-21T15:32:14 in micro_seconds" do
    units = :erlang.convert_time_unit(298827134, :seconds, :micro_seconds)
    assert units == decode(:micro_seconds, -647857666000000)
  end

  test "1979-06-21T15:32:14 in milli_seconds" do
    units = :erlang.convert_time_unit(298827134, :seconds, :milli_seconds)
    assert units == decode(:milli_seconds, -647857666000000)
  end

  test "1979-06-21T15:32:14 in seconds" do
    units = :erlang.convert_time_unit(298827134, :seconds, :seconds)
    assert units == decode(:seconds, -647857666000000)
  end

  test "1979-06-21T15:32:14 in native units" do
    units = :erlang.convert_time_unit(298827134, :seconds, :native)
    assert units == decode(-647857666000000)
  end

  test "1999-12-31T23:59:59 in native units" do
    units = :erlang.convert_time_unit(946684799, :seconds, :native)
    assert units == decode(-1000000)
  end

  test "2000-01-01T00:00:00 in native units" do
    units = :erlang.convert_time_unit(946684800, :seconds, :native)
    assert units == decode(0)
  end

  test "2000-01-01T00:00:01 in native units" do
    units = :erlang.convert_time_unit(946684801, :seconds, :native)
    assert units == decode(1000000)
  end

  test "2016-02-03T07:32:45 in native units" do
    units = :erlang.convert_time_unit(1454484765, :seconds, :native)
    assert units == decode(507799965000000)
  end
end

