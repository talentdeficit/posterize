defmodule Posterize.Extensions.Date.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp encode(val) do
    :posterize_xt_date.do_encode(val)
  end

  test "infinity" do
    assert <<4::int32, 2_147_483_647::int32>> == encode(:infinity)
  end

  test "-infinity" do
    assert <<4::int32, -2_147_483_648::int32>> == encode(:"-infinity")
  end

  test "{ -4713, 1, 1 }" do
    assert <<4::int32, -2_451_507::int32>> == encode({-4713, 1, 1})
  end

  ## proleptic gregorian calendar eap year
  test "{ -4713, 2, 29 }" do
    assert <<4::int32, -2_451_448::int32>> == encode({-4713, 2, 29})
  end

  test "{ -1, 1, 1 }" do
    assert <<4::int32, -730_485::int32>> == encode({-1, 1, 1})
  end

  # proleptic gregorian calendar leap year
  test "{ -1, 2, 29 }" do
    assert <<4::int32, -730_426::int32>> == encode({-1, 2, 29})
  end

  # proleptic gregorian calendar leap year
  test "{ -401, 2, 29 }" do
    assert <<4::int32, -876_523::int32>> == encode({-401, 2, 29})
  end

  # proleptic gregorian calendar leap year
  test "{ 4, 2, 29 }" do
    assert <<4::int32, -728_965::int32>> == encode({4, 2, 29})
  end

  # proleptic gregorian calendar leap year
  test "{ 400, 2, 29 }" do
    assert <<4::int32, -584_329::int32>> == encode({400, 2, 29})
  end

  test "{ 1979, 6, 21 }" do
    assert <<4::int32, -7499::int32>> == encode({1979, 6, 21})
  end

  test "{ 1999, 12, 31 }" do
    assert <<4::int32, -1::int32>> == encode({1999, 12, 31})
  end

  test "{ 2000, 1, 1 }" do
    assert <<4::int32, 0::int32>> == encode({2000, 1, 1})
  end

  test "{ 2000, 1, 2 }" do
    assert <<4::int32, 1::int32>> == encode({2000, 1, 2})
  end

  test "{ 2000, 2, 1 }" do
    assert <<4::int32, 31::int32>> == encode({2000, 2, 1})
  end

  test "{ 2001, 1, 1 }" do
    # i got this test wrong because i forgot 2000 was a leap year
    assert <<4::int32, 366::int32>> == encode({2001, 1, 1})
  end

  test "{ 5874897, 12, 31 }" do
    assert <<4::int32, 2_145_031_948::int32>> == encode({5_874_897, 12, 31})
  end

  test "{ -101, 2, 29 }" do
    assert_raise ArgumentError, fn -> encode({-101, 2, 29}) end
  end

  test "{ 100, 2, 29 }" do
    assert_raise ArgumentError, fn -> encode({100, 2, 29}) end
  end
end

defmodule Posterize.Extensions.Date.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp decode(val) do
    :posterize_xt_date.do_decode(val)
  end

  test "infinity" do
    assert :infinity == decode(2_147_483_647)
  end

  test "-infinity" do
    assert :"-infinity" == decode(-2_147_483_648)
  end

  test "{ -4713, 1, 1 }" do
    assert {-4713, 1, 1} == decode(-2_451_507)
  end

  test "{ -4713, 2, 29 }" do
    assert {-4713, 2, 29} == decode(-2_451_448)
  end

  test "{ -1, 1, 1 }" do
    assert {-1, 1, 1} == decode(-730_485)
  end

  test "{ -1, 2, 29 }" do
    assert {-1, 2, 29} == decode(-730_426)
  end

  test "{ -401, 2, 29 }" do
    assert {-401, 2, 29} == decode(-876_523)
  end

  test "{ 4, 2, 29 }" do
    assert {4, 2, 29} == decode(-728_965)
  end

  test "{ 400, 2, 29 }" do
    assert {400, 2, 29} == decode(-584_329)
  end

  test "{ 1979, 6, 21 }" do
    assert {1979, 6, 21} == decode(-7499)
  end

  test "{ 1999, 12, 31 }" do
    assert {1999, 12, 31} == decode(-1)
  end

  test "{ 2000, 1, 1 }" do
    assert {2000, 1, 1} == decode(0)
  end

  test "{ 2000, 1, 2 }" do
    assert {2000, 1, 2} == decode(1)
  end

  test "{ 2000, 2, 1 }" do
    assert {2000, 2, 1} == decode(31)
  end

  test "{ 2001, 1, 1 }" do
    assert {2001, 1, 1} == decode(366)
  end

  test "{ 5874897, 12, 31 }" do
    assert {5_874_897, 12, 31} == decode(2_145_031_948)
  end
end
