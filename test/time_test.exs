defmodule Posterize.Extensions.Time.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp encode(units, time) do
    :posterize_xt_time.do_encode(units, time)
  end
  defp encode(time) do
    :posterize_xt_time.do_encode(:native, time)
  end

  test "0" do
    assert << 8 :: int32, 0 :: int64 >> == encode(0)
  end

  test "1 nanosecond" do
    assert << 8 :: int32, 0 :: int64 >> == encode(:nano_seconds, 1)
  end

  test "-1 nanosecond" do
    assert << 8 :: int32, -1 :: int64 >> == encode(:nano_seconds, -1)
  end

  test "1 microsecond" do
    assert << 8 :: int32, 1 :: int64 >> == encode(:micro_seconds, 1)
  end

  test "-1 microsecond" do
    assert << 8 :: int32, -1 :: int64 >> == encode(:micro_seconds, -1)
  end

  test "1 millisecond" do
    assert << 8 :: int32, 1000 :: int64 >> == encode(:milli_seconds, 1)
  end

  test "-1 millisecond" do
    assert << 8 :: int32, -1000 :: int64 >> == encode(:milli_seconds, -1)
  end

  test "1 second" do
    assert << 8 :: int32, 1000000 :: int64 >> == encode(:seconds, 1)
  end

  test "-1 second" do
    assert << 8 :: int32, -1000000 :: int64 >> == encode(:seconds, -1)
  end

  test "1 second in nanoseconds" do
    assert << 8 :: int32, 1000000 :: int64 >> == encode(:nano_seconds, :erlang.convert_time_unit(1, :seconds, :nano_seconds))
  end

  test "1 second in microseconds" do
    assert << 8 :: int32, 1000000 :: int64 >> == encode(:micro_seconds, :erlang.convert_time_unit(1, :seconds, :micro_seconds))
  end

  test "1 second in milliseconds" do
    assert << 8 :: int32, 1000000 :: int64 >> == encode(:milli_seconds, :erlang.convert_time_unit(1, :seconds, :milli_seconds))
  end

  test "1 second in seconds" do
    assert << 8 :: int32, 1000000 :: int64 >> == encode(:seconds, 1)
  end

  test "1 second in native units" do
    assert << 8 :: int32, 1000000 :: int64 >> == encode(:erlang.convert_time_unit(1, :seconds, :native))
  end

  test "1 minute in native units" do
    assert << 8 :: int32, 60000000 :: int64 >> == encode(:erlang.convert_time_unit(60, :seconds, :native))
  end

  test "1 hour in native units" do
    assert << 8 :: int32, 3600000000 :: int64 >> == encode(:erlang.convert_time_unit(60 * 60, :seconds, :native))
  end

  test "1 hour 1 minute 1 second in native units" do
    assert << 8 :: int32, 3661000000 :: int64 >> == encode(:erlang.convert_time_unit((60 * 60) + 61, :seconds, :native))
  end

  test "23 hours, 59 minutes and 59 seconds in seconds" do
    assert << 8 :: int32, 86399000000 :: int64 >> == encode(:seconds, 86399)
  end
end

defmodule Posterize.Extensions.Time.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp decode(units, time) do
    :posterize_xt_time.do_decode(units, time)
  end
  defp decode(time) do
    :posterize_xt_time.do_decode(:native, time)
  end

  test "0" do
    assert 0 == decode(0)
  end

  test "1 microsecond" do
    assert 1 == decode(:micro_seconds, 1)
  end

  test "-1 microsecond" do
    assert -1 == decode(:micro_seconds, -1)
  end

  test "1 millisecond" do
    assert 1 == decode(:milli_seconds, 1000)
  end

  test "-1 millisecond" do
    assert -1 == decode(:milli_seconds, -1000)
  end

  test "1 second" do
    assert 1 == decode(:seconds, 1000000)
  end

  test "-1 second" do
    assert -1 == decode(:seconds, -1000000)
  end

  test "1 second in native units" do
    time = :erlang.convert_time_unit(1, :seconds, :native)
    assert time == decode(1000000)
  end

  test "-1 second in native units" do
    time = :erlang.convert_time_unit(-1, :seconds, :native)
    assert time == decode(-1000000)
  end

  test "1 minute in native units" do
    time = :erlang.convert_time_unit(60, :seconds, :native)
    assert time == decode(60000000)
  end

  test "1 hour in native units" do
    time = :erlang.convert_time_unit(3600, :seconds, :native)
    assert time == decode(3600000000)
  end

  test "23 hours 59 minutes 59 seconds in native units" do
    time = :erlang.convert_time_unit(86399, :seconds, :native)
    assert time == decode(86399000000)
  end
end