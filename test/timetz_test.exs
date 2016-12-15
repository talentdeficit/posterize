defmodule Posterize.Extensions.TimeTz.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp encode({units, count}) do
    :posterize_xt_timetz.do_encode(units, count)
  end
  defp encode(count) do
    :posterize_xt_timetz.do_encode(:native, count)
  end

  test "{0, 0, 0}" do
    assert <<12 :: int32, 0 :: int64, 0 :: int32>> == encode(0)
  end

  test "{0, 0, 1} in nanoseconds" do
    assert <<12 :: int32, 1000000 :: int64, 0 :: int32>> == encode({:nano_seconds, 1000000000})
  end

  test "{0, 0, 1} in microseconds" do
    assert <<12 :: int32, 1000000 :: int64, 0 :: int32>> == encode({:micro_seconds, 1000000})
  end

  test "{0, 0, 1} in milliseconds" do
    assert <<12 :: int32, 1000000 :: int64, 0 :: int32>> == encode({:milli_seconds, 1000})
  end

  test "{0, 0, 1} in seconds" do
    assert <<12 :: int32, 1000000 :: int64, 0 :: int32>> == encode({:seconds, 1})
  end

  test "{0, 0, 1}" do
    assert <<12 :: int32, 1000000 :: int64, 0 :: int32>> == encode(:erlang.convert_time_unit(1, :seconds, :native))
  end

  test "{0, 1, 0}" do
    assert <<12 :: int32, 60000000 :: int64, 0 :: int32>> == encode({:micro_seconds, 60000000})
  end

  test "{1, 0, 0}" do
    assert <<12 :: int32, 3600000000 :: int64, 0 :: int32>> == encode({:micro_seconds, 3600000000})
  end

  test "{1, 1, 1}" do
    assert <<12 :: int32, 3661000000 :: int64, 0 :: int32>> == encode({:micro_seconds, 3661000000})
  end

  test "{23, 59, 59}" do
    assert <<12 :: int32, 86399000000 :: int64, 0 :: int32>> == encode({:micro_seconds, 86399000000})
  end
end

defmodule Posterize.Extensions.TimeTz.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp decode(usecs, tz) do
    :posterize_xt_timetz.do_decode(usecs, tz)
  end

  test "{0, 0, 0}" do
    assert 0 == decode(0, 0)
  end

  test "{0, 0, 1}" do
    units = :erlang.convert_time_unit(1, :seconds, :native)
    assert units == decode(1000000, 0)
  end

  test "{0, 1, 0}" do
    units = :erlang.convert_time_unit(60, :seconds, :native)
    assert units == decode(60000000, 0)
  end

  test "{1, 0, 0}" do
    units = :erlang.convert_time_unit(3600, :seconds, :native)
    assert units == decode(3600000000, 0)
  end

  test "{23, 59, 59}" do
    units = :erlang.convert_time_unit(86399, :seconds, :native)
    assert units == decode(86399000000, 0)
  end
end