defmodule Posterize.Extensions.Date.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp encode(val) do
    :posterize_xt_date.do_encode(val)
  end

  test "{1979, 6, 21}" do
    assert <<4 :: int32, -7499 :: int32>> == encode({1979, 6, 21})
  end

  test "{1999, 12, 31}" do
    assert <<4 :: int32, -1 :: int32>> == encode({1999, 12, 31})
  end

  test "{2000, 1, 1}" do
    assert <<4 :: int32, 0 :: int32>> == encode({2000, 1, 1})
  end

  test "{2000, 1, 2}" do
    assert <<4 :: int32, 1 :: int32>> == encode({2000, 1, 2})
  end

  test "{2000, 2, 1}" do
    assert <<4 :: int32, 31 :: int32>> == encode({2000, 2, 1})
  end

  test "{2001, 1, 1}" do
    # i got this test wrong because i forgot 2000 was a leap year
    assert <<4 :: int32, 366 :: int32>> == encode({2001, 1, 1})
  end
end

defmodule Posterize.Extensions.Date.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp decode(val) do
    :posterize_xt_date.do_decode(val)
  end

  test "{1979, 6, 21}" do
    assert {1979, 6, 21} == decode(-7499)
  end

  test "{1999, 12, 31}" do
    assert {1999, 12, 31} == decode(-1)
  end

  test "{2000, 1, 1}" do
    assert {2000, 1, 1} == decode(0)
  end

  test "{2000, 1, 2}" do
    assert {2000, 1, 2} == decode(1)
  end

  test "{2000, 2, 1}" do
    assert {2000, 2, 1} == decode(31)
  end

  test "{2001, 1, 1}" do
    assert {2001, 1, 1} == decode(366)
  end
end
