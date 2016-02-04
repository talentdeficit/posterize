defmodule Posterize.Extensions.Integer.Date.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{1979, 6, 21} in nanoseconds" do
    assert << -7499 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, {:nano_seconds, 298771200000000000}, [], [])
  end

  test "{1979, 6, 21} in microseconds" do
    assert << -7499 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, {:micro_seconds, 298771200000000}, [], [])
  end

  test "{1979, 6, 21} in milliseconds" do
    assert << -7499 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, {:milli_seconds, 298771200000}, [], [])
  end

  test "{1979, 6, 21} in seconds" do
    assert << -7499 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, {:seconds, 298771200}, [], [])
  end

  test "{1979, 6, 21}" do
    assert << -7499 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, :erlang.convert_time_unit(298771200, :seconds, :native), [], [])
  end

  test "{1999, 12, 31}" do
    assert << -1 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, {:micro_seconds, 946598400000000}, [], [])
  end

  test "{2000, 1, 1}" do
    assert << 0 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, {:micro_seconds, 946684800000000}, [], [])
  end

  test "{2000, 1, 2}" do
    assert << 1 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, {:micro_seconds, 946771200000000}, [], [])
  end

  test "{2000, 2, 1}" do
    assert << 31 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, {:micro_seconds, 949363200000000}, [], [])
  end

  test "{2001, 1, 1}" do
    # i got this test wrong because i forgot 2000 was a leap year
    assert << 366 :: int32 >> == Posterize.Extensions.Integer.Date.encode(@type_info, {:micro_seconds, 978307200000000}, [], [])
  end
end

defmodule Posterize.Extensions.Integer.Date.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{1979, 6, 21}" do
    units = :erlang.convert_time_unit(298771200000000, :micro_seconds, :native)
    assert units == Posterize.Extensions.Integer.Date.decode(@type_info, << -7499 :: int32 >>, [], [])
  end

  test "{1999, 12, 31}" do
    units = :erlang.convert_time_unit(946598400000000, :micro_seconds, :native)
    assert units == Posterize.Extensions.Integer.Date.decode(@type_info, << -1 :: int32 >>, [], [])
  end

  test "{2000, 1, 1}" do
    units = :erlang.convert_time_unit(946684800000000, :micro_seconds, :native)
    assert units == Posterize.Extensions.Integer.Date.decode(@type_info, << 0 :: int32 >>, [], [])
  end

  test "{2000, 1, 2}" do
    units = :erlang.convert_time_unit(946771200000000, :micro_seconds, :native)
    assert units == Posterize.Extensions.Integer.Date.decode(@type_info, << 1 :: int32 >>, [], [])
  end

  test "{2000, 2, 1}" do
    units = :erlang.convert_time_unit(949363200000000, :micro_seconds, :native)
    assert units == Posterize.Extensions.Integer.Date.decode(@type_info, << 31 :: int32 >>, [], [])
  end

  test "{2001, 1, 1}" do
    units = :erlang.convert_time_unit(978307200000000, :micro_seconds, :native)
    assert units == Posterize.Extensions.Integer.Date.decode(@type_info, << 366 :: int32 >>, [], [])
  end
end

defmodule Posterize.Extensions.Integer.Time.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{0, 0, 0}" do
    assert << 0 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, 0, [], [])
  end

  test "{0, 0, 1} in nanoseconds" do
    assert << 1000000 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, {:nano_seconds, 1000000000}, [], [])
  end

  test "{0, 0, 1} in microseconds" do
    assert << 1000000 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, {:micro_seconds, 1000000}, [], [])
  end

  test "{0, 0, 1} in milliseconds" do
    assert << 1000000 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, {:milli_seconds, 1000}, [], [])
  end

  test "{0, 0, 1} in seconds" do
    assert << 1000000 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, {:seconds, 1}, [], [])
  end

  test "{0, 0, 1}" do
    assert << 1000000 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, :erlang.convert_time_unit(1, :seconds, :native), [], [])
  end

  test "{0, 1, 0}" do
    assert << 60000000 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, {:micro_seconds, 60000000}, [], [])
  end

  test "{1, 0, 0}" do
    assert << 3600000000 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, {:micro_seconds, 3600000000}, [], [])
  end

  test "{1, 1, 1}" do
    assert << 3661000000 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, {:micro_seconds, 3661000000}, [], [])
  end

  test "{23, 59, 59}" do
    assert << 86399000000 :: int64 >> == Posterize.Extensions.Integer.Time.encode(@type_info, {:micro_seconds, 86399000000}, [], [])
  end
end

defmodule Posterize.Extensions.Integer.Time.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{0, 0, 0}" do
    assert 0 == Posterize.Extensions.Integer.Time.decode(@type_info, << 0 :: int64 >>, [], [])
  end

  test "{0, 0, 1}" do
    units = :erlang.convert_time_unit(1, :seconds, :native)
    assert units == Posterize.Extensions.Integer.Time.decode(@type_info, << 1000000 :: int64 >>, [], [])
  end

  test "{0, 1, 0}" do
    units = :erlang.convert_time_unit(60, :seconds, :native)
    assert units == Posterize.Extensions.Integer.Time.decode(@type_info, << 60000000 :: int64 >>, [], [])
  end

  test "{1, 0, 0}" do
    units = :erlang.convert_time_unit(3600, :seconds, :native)
    assert units == Posterize.Extensions.Integer.Time.decode(@type_info, << 3600000000 :: int64 >>, [], [])
  end

  test "{23, 59, 59}" do
    units = :erlang.convert_time_unit(86399, :seconds, :native)
    assert units == Posterize.Extensions.Integer.Time.decode(@type_info, << 86399000000 :: int64 >>, [], [])
  end
end

defmodule Posterize.Extensions.Integer.DateTime.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{{1999, 12, 31}, {23, 59, 59}} in nanoseconds" do
    assert << -1000000 :: int64 >> == Posterize.Extensions.Integer.DateTime.encode(@type_info, {:nano_seconds, 946684799000000000}, [], [])
  end

  test "{{1999, 12, 31}, {23, 59, 59}} in microseconds" do
    assert << -1000000 :: int64 >> == Posterize.Extensions.Integer.DateTime.encode(@type_info, {:micro_seconds, 946684799000000}, [], [])
  end

  test "{{1999, 12, 31}, {23, 59, 59}} in milliseconds" do
    assert << -1000000 :: int64 >> == Posterize.Extensions.Integer.DateTime.encode(@type_info, {:milli_seconds, 946684799000}, [], [])
  end

  test "{{1999, 12, 31}, {23, 59, 59}} in seconds" do
    assert << -1000000 :: int64 >> == Posterize.Extensions.Integer.DateTime.encode(@type_info, {:seconds, 946684799}, [], [])
  end

  test "{{1999, 12, 31}, {23, 59, 59}}" do
    assert << -1000000 :: int64 >> == Posterize.Extensions.Integer.DateTime.encode(@type_info, :erlang.convert_time_unit(946684799, :seconds, :native), [], [])
  end

  test "{{2000, 1, 1}, {0, 0, 0}}" do
    assert << 0 :: int64 >> == Posterize.Extensions.Integer.DateTime.encode(@type_info, {:micro_seconds, 946684800000000}, [], [])
  end

  test "{{2000, 1, 1}, {0, 0, 1}}" do
    assert << 1000000 :: int64 >> == Posterize.Extensions.Integer.DateTime.encode(@type_info, {:micro_seconds, 946684801000000}, [], [])
  end

  test "{{2016, 2, 3}, {7, 32, 45}}" do
    assert << 507799965000000 :: int64 >> == Posterize.Extensions.Integer.DateTime.encode(@type_info, {:micro_seconds, 1454484765000000}, [], [])
  end
end

defmodule Posterize.Extensions.Integer.DateTime.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{{1979, 6, 21}, {15, 32, 14}}" do
    units = :erlang.convert_time_unit(298827134, :seconds, :native)
    assert units == Posterize.Extensions.Integer.DateTime.decode(@type_info, << -647857666000000 :: int64 >>, [], [])
  end

  test "{{1999, 12, 31}, {23, 59, 59}}" do
    units = :erlang.convert_time_unit(946684799, :seconds, :native)
    assert units == Posterize.Extensions.Integer.DateTime.decode(@type_info, << -1000000 :: int64 >>, [], [])
  end

  test "{{2000, 1, 1}, {0, 0, 0}}" do
    units = :erlang.convert_time_unit(946684800, :seconds, :native)
    assert units == Posterize.Extensions.Integer.DateTime.decode(@type_info, << 0 :: int64 >>, [], [])
  end

  test "{{2000, 1, 1}, {0, 0, 1}}" do
    units = :erlang.convert_time_unit(946684801, :seconds, :native)
    assert units == Posterize.Extensions.Integer.DateTime.decode(@type_info, << 1000000 :: int64 >>, [], [])
  end

  test "{{2016, 2, 3}, {7, 32, 45}}" do
    units = :erlang.convert_time_unit(1454484765, :seconds, :native)
    assert units == Posterize.Extensions.Integer.DateTime.decode(@type_info, << 507799965000000 :: int64 >>, [], [])
  end
end

defmodule Posterize.Extensions.Integer.Interval.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "0" do
    assert << 0 :: int64, 0 :: int32, 0 :: int32 >> == Posterize.Extensions.Integer.Interval.encode(@type_info, 0, [], [])
  end

  test "1234567890 in seconds" do
    assert << 1234567890000000 :: int64, 0 :: int32, 0 :: int32 >> == Posterize.Extensions.Integer.Interval.encode(@type_info, {:seconds, 1234567890}, [], [])
  end

  test "1234567890 in milliseconds" do
    assert << 1234567890000 :: int64, 0 :: int32, 0 :: int32 >> == Posterize.Extensions.Integer.Interval.encode(@type_info, {:milli_seconds, 1234567890}, [], [])
  end

  test "1234567890 in microseconds" do
    assert << 1234567890 :: int64, 0 :: int32, 0 :: int32 >> == Posterize.Extensions.Integer.Interval.encode(@type_info, {:micro_seconds, 1234567890}, [], [])
  end

  test "1234567890 in nanoseconds" do
    assert << 1234567 :: int64, 0 :: int32, 0 :: int32 >> == Posterize.Extensions.Integer.Interval.encode(@type_info, {:nano_seconds, 1234567890}, [], [])
  end

  test "1234567890" do
    assert << 1234567890000000 :: int64, 0 :: int32, 0 :: int32 >> == Posterize.Extensions.Integer.Interval.encode(@type_info, :erlang.convert_time_unit(1234567890, :seconds, :native), [], [])
  end
end

defmodule Posterize.Extensions.Integer.Interval.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "0" do
    assert 0 == Posterize.Extensions.Integer.Interval.decode(@type_info, << 0 :: int64, 0 :: int32, 0 :: int32 >>, [], [])
  end

  test "1234567890" do
    units = :erlang.convert_time_unit(1234567890, :micro_seconds, :native)
    assert units == Posterize.Extensions.Integer.Interval.decode(@type_info, << 1234567890 :: int64, 0 :: int32, 0 :: int32 >>, [], [])
  end
end