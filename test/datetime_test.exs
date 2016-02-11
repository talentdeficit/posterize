defmodule Posterize.Extensions.Date.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{1979, 6, 21}" do
    assert << -7499 :: int32 >> == Posterize.Extensions.Date.encode(@type_info, {1979, 6, 21}, [], [])
  end

  test "{1999, 12, 31}" do
    assert << -1 :: int32 >> == Posterize.Extensions.Date.encode(@type_info, {1999, 12, 31}, [], [])
  end

  test "{2000, 1, 1}" do
    assert << 0 :: int32 >> == Posterize.Extensions.Date.encode(@type_info, {2000, 1, 1}, [], [])
  end

  test "{2000, 1, 2}" do
    assert << 1 :: int32 >> == Posterize.Extensions.Date.encode(@type_info, {2000, 1, 2}, [], [])
  end

  test "{2000, 2, 1}" do
    assert << 31 :: int32 >> == Posterize.Extensions.Date.encode(@type_info, {2000, 2, 1}, [], [])
  end

  test "{2001, 1, 1}" do
    # i got this test wrong because i forgot 2000 was a leap year
    assert << 366 :: int32 >> == Posterize.Extensions.Date.encode(@type_info, {2001, 1, 1}, [], [])
  end
end

defmodule Posterize.Extensions.Date.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{1979, 6, 21}" do
    assert {1979, 6, 21} == Posterize.Extensions.Date.decode(@type_info, << -7499 :: int32 >>, [], [])
  end

  test "{1999, 12, 31}" do
    assert {1999, 12, 31} == Posterize.Extensions.Date.decode(@type_info, << -1 :: int32 >>, [], [])
  end

  test "{2000, 1, 1}" do
    assert {2000, 1, 1} == Posterize.Extensions.Date.decode(@type_info, << 0 :: int32 >>, [], [])
  end

  test "{2000, 1, 2}" do
    assert {2000, 1, 2} == Posterize.Extensions.Date.decode(@type_info, << 1 :: int32 >>, [], [])
  end

  test "{2000, 2, 1}" do
    assert {2000, 2, 1} == Posterize.Extensions.Date.decode(@type_info, << 31 :: int32 >>, [], [])
  end

  test "{2001, 1, 1}" do
    assert {2001, 1, 1} == Posterize.Extensions.Date.decode(@type_info, << 366 :: int32 >>, [], [])
  end
end

defmodule Posterize.Extensions.Time.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{0, 0, 0}" do
    assert << 0 :: int64 >> == Posterize.Extensions.Time.encode(@type_info, {0, 0, 0}, [], [])
  end

  test "{0, 0, 1}" do
    assert << 1000000 :: int64 >> == Posterize.Extensions.Time.encode(@type_info, {0, 0, 1}, [], [])
  end

  test "{0, 1, 0}" do
    assert << 60000000 :: int64 >> == Posterize.Extensions.Time.encode(@type_info, {0, 1, 0}, [], [])
  end

  test "{1, 0, 0}" do
    assert << 3600000000 :: int64 >> == Posterize.Extensions.Time.encode(@type_info, {1, 0, 0}, [], [])
  end

  test "{1, 1, 1}" do
    assert << 3661000000 :: int64 >> == Posterize.Extensions.Time.encode(@type_info, {1, 1, 1}, [], [])
  end

  test "{23, 59, 59}" do
    assert << 86399000000 :: int64 >> == Posterize.Extensions.Time.encode(@type_info, {23, 59, 59}, [], [])
  end
end

defmodule Posterize.Extensions.Time.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{0, 0, 0}" do
    assert {0, 0, 0} == Posterize.Extensions.Time.decode(@type_info, << 0 :: int64 >>, [], [])
  end

  test "{0, 0, 1}" do
    assert {0, 0, 1} == Posterize.Extensions.Time.decode(@type_info, << 1000000 :: int64 >>, [], [])
  end

  test "{0, 1, 0}" do
    assert {0, 1, 0} == Posterize.Extensions.Time.decode(@type_info, << 60000000 :: int64 >>, [], [])
  end

  test "{1, 0, 0}" do
    assert {1, 0, 0} == Posterize.Extensions.Time.decode(@type_info, << 3600000000 :: int64 >>, [], [])
  end

  test "{23, 59, 59}" do
    assert {23, 59, 59} == Posterize.Extensions.Time.decode(@type_info, << 86399000000 :: int64 >>, [], [])
  end
end

defmodule Posterize.Extensions.DateTime.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{{1999, 12, 31}, {23, 59, 59}}" do
    assert << -1000000 :: int64 >> == Posterize.Extensions.DateTime.encode(@type_info, {{1999, 12, 31}, {23, 59, 59}}, [], [])
  end

  test "{{2000, 1, 1}, {0, 0, 0}}" do
    assert << 0 :: int64 >> == Posterize.Extensions.DateTime.encode(@type_info, {{2000, 1, 1}, {0, 0, 0}}, [], [])
  end

  test "{{2000, 1, 1}, {0, 0, 1}}" do
    assert << 1000000 :: int64 >> == Posterize.Extensions.DateTime.encode(@type_info, {{2000, 1, 1}, {0, 0, 1}}, [], [])
  end

  test "{{2016, 2, 3}, {7, 32, 45}}" do
    assert << 507799965000000 :: int64 >> == Posterize.Extensions.DateTime.encode(@type_info, {{2016, 2, 3}, {7, 32, 45}}, [], [])
  end
end

defmodule Posterize.Extensions.DateTime.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{{1979, 6, 21}, {15, 32, 14}}" do
    assert {{1979, 6, 21}, {15, 32, 14}} == Posterize.Extensions.DateTime.decode(@type_info, << -647857666000000 :: int64 >>, [], [])
  end

  test "{{1999, 12, 31}, {23, 59, 59}}" do
    assert {{1999, 12, 31}, {23, 59, 59}} == Posterize.Extensions.DateTime.decode(@type_info, << -1000000 :: int64 >>, [], [])
  end

  test "{{2000, 1, 1}, {0, 0, 0}}" do
    assert {{2000, 1, 1}, {0, 0, 0}} == Posterize.Extensions.DateTime.decode(@type_info, << 0 :: int64 >>, [], [])
  end

  test "{{2000, 1, 1}, {0, 0, 1}}" do
    assert {{2000, 1, 1}, {0, 0, 1}} == Posterize.Extensions.DateTime.decode(@type_info, << 1000000 :: int64 >>, [], [])
  end

  test "{{2016, 2, 3}, {7, 32, 45}}" do
    assert {{2016, 2, 3}, {7, 32, 45}} == Posterize.Extensions.DateTime.decode(@type_info, << 507799965000000 :: int64 >>, [], [])
  end
end

defmodule Posterize.Extensions.Interval.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{{0, 0, 0}, 0, 0}" do
    assert << 0 :: int64, 0 :: int32, 0 :: int32 >> == Posterize.Extensions.Interval.encode(@type_info, {{0, 0, 0}, 0, 0}, [], [])
  end

  test "{{0, 0, 0}, 158, 7}" do
    assert << 0 :: int64, 158 :: int32, 7 :: int32 >> == Posterize.Extensions.Interval.encode(@type_info, {{0, 0, 0}, 158, 7}, [], [])
  end
end

defmodule Posterize.Extensions.Interval.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils

  @type_info %Postgrex.TypeInfo{}

  test "{{0, 0, 0}, 0, 0}" do
    assert {{0, 0, 0}, 0, 0} == Posterize.Extensions.Interval.decode(@type_info, << 0 :: int64, 0 :: int32, 0 :: int32 >>, [], [])
  end

  test "{{0, 0, 0}, 302, 7}" do
    assert {{0, 0, 0}, 302, 7} == Posterize.Extensions.Interval.decode(@type_info, << 0 :: int64, 302 :: int32, 7 :: int32 >>, [], [])
  end
end