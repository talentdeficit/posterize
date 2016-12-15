defmodule Posterize.Extensions.Integer.Timestamp.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  defp encode({units, count}) do
    :posterize_xt_timestamp.do_encode(units, count)
  end
  defp encode(count) do
    :posterize_xt_timestamp.do_encode(:native, count)
  end

  test "{{1999, 12, 31}, {23, 59, 59}} in nanoseconds" do
    assert <<8 :: int32, -1000000 :: int64>> == encode({:nano_seconds, 946684799000000000})
  end

  test "{{1999, 12, 31}, {23, 59, 59}} in microseconds" do
    assert <<8 :: int32, -1000000 :: int64>> == encode({:micro_seconds, 946684799000000})
  end

  test "{{1999, 12, 31}, {23, 59, 59}} in milliseconds" do
    assert <<8 :: int32, -1000000 :: int64>> == encode({:milli_seconds, 946684799000})
  end

  test "{{1999, 12, 31}, {23, 59, 59}} in seconds" do
    assert <<8 :: int32, -1000000 :: int64>> == encode({:seconds, 946684799})
  end

  test "{{1999, 12, 31}, {23, 59, 59}}" do
    assert <<8 :: int32, -1000000 :: int64>> == encode(:erlang.convert_time_unit(946684799, :seconds, :native))
  end

  test "{{2000, 1, 1}, {0, 0, 0}}" do
    assert <<8 :: int32, 0 :: int64>> == encode({:micro_seconds, 946684800000000})
  end

  test "{{2000, 1, 1}, {0, 0, 1}}" do
    assert <<8 :: int32, 1000000 :: int64>> == encode({:micro_seconds, 946684801000000})
  end

  test "{{2016, 2, 3}, {7, 32, 45}}" do
    assert <<8 :: int32, 507799965000000 :: int64>> == encode({:micro_seconds, 1454484765000000})
  end
end

defmodule Posterize.Extensions.Integer.DateTime.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  defp decode(val) do
    :posterize_xt_timestamp.do_decode(val)
  end

  test "{{1979, 6, 21}, {15, 32, 14}}" do
    units = :erlang.convert_time_unit(298827134, :seconds, :native)
    assert units == decode(-647857666000000)
  end

  test "{{1999, 12, 31}, {23, 59, 59}}" do
    units = :erlang.convert_time_unit(946684799, :seconds, :native)
    assert units == decode(-1000000)
  end

  test "{{2000, 1, 1}, {0, 0, 0}}" do
    units = :erlang.convert_time_unit(946684800, :seconds, :native)
    assert units == decode(0)
  end

  test "{{2000, 1, 1}, {0, 0, 1}}" do
    units = :erlang.convert_time_unit(946684801, :seconds, :native)
    assert units == decode(1000000)
  end

  test "{{2016, 2, 3}, {7, 32, 45}}" do
    units = :erlang.convert_time_unit(1454484765, :seconds, :native)
    assert units == decode(507799965000000)
  end
end

