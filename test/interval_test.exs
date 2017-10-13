defmodule Posterize.Extensions.Interval.Encode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp encode(val) do
    :posterize_xt_interval.do_encode(val)
  end

  test "0 microseconds" do
    assert <<16::int32, 0::int64, 0::int32, 0::int32>> == encode(%{microseconds: 0})
  end

  test "1 microsecond" do
    assert <<16::int32, 1::int64, 0::int32, 0::int32>> == encode(%{microseconds: 1})
  end

  test "-1 microsecond" do
    assert <<16::int32, -1::int64, 0::int32, 0::int32>> == encode(%{microseconds: -1})
  end

  test "1 second" do
    assert <<16::int32, 1_000_000::int64, 0::int32, 0::int32>> == encode(%{seconds: 1})
  end

  test "-1 second" do
    assert <<16::int32, -1_000_000::int64, 0::int32, 0::int32>> == encode(%{seconds: -1})
  end

  test "1 minute" do
    assert <<16::int32, 60_000_000::int64, 0::int32, 0::int32>> == encode(%{minutes: 1})
  end

  test "-1 minute" do
    assert <<16::int32, -60_000_000::int64, 0::int32, 0::int32>> == encode(%{minutes: -1})
  end

  test "1 hour" do
    assert <<16::int32, 3_600_000_000::int64, 0::int32, 0::int32>> == encode(%{hours: 1})
  end

  test "-1 hour" do
    assert <<16::int32, -3_600_000_000::int64, 0::int32, 0::int32>> == encode(%{hours: -1})
  end

  test "1 day" do
    assert <<16::int32, 0::int64, 1::int32, 0::int32>> == encode(%{days: 1})
  end

  test "-1 day" do
    assert <<16::int32, 0::int64, -1::int32, 0::int32>> == encode(%{days: -1})
  end

  test "1 week" do
    assert <<16::int32, 0::int64, 7::int32, 0::int32>> == encode(%{weeks: 1})
  end

  test "-1 week" do
    assert <<16::int32, 0::int64, -7::int32, 0::int32>> == encode(%{weeks: -1})
  end

  test "1 month" do
    assert <<16::int32, 0::int64, 0::int32, 1::int32>> == encode(%{months: 1})
  end

  test "-1 month" do
    assert <<16::int32, 0::int64, 0::int32, -1::int32>> == encode(%{months: -1})
  end

  test "1 year" do
    assert <<16::int32, 0::int64, 0::int32, 12::int32>> == encode(%{years: 1})
  end

  test "-1 year" do
    assert <<16::int32, 0::int64, 0::int32, -12::int32>> == encode(%{years: -1})
  end

  test "3 years, 7 months, 5 weeks, 2 days, 4 hours, 23 minutes, 17 seconds" do
    interval = %{years: 3, months: 7, weeks: 5, days: 2, hours: 4, minutes: 23, seconds: 17}
    assert <<16::int32, 15_797_000_000::int64, 37::int32, 43::int32>> == encode(interval)
  end
end

defmodule Posterize.Extensions.Interval.Decode.Test do
  use ExUnit.Case
  import Postgrex.BinaryUtils, warn: false

  defp decode(months, days, microseconds) do
    :posterize_xt_interval.do_decode(months, days, microseconds)
  end

  test "0 microseconds" do
    assert %{microseconds: 0} == decode(0, 0, 0)
  end

  test "1 microsecond" do
    assert %{microseconds: 1} == decode(0, 0, 1)
  end

  test "-1 microsecond" do
    assert %{microseconds: -1} == decode(0, 0, -1)
  end

  test "1 day" do
    assert %{days: 1, microseconds: 0} == decode(0, 1, 0)
  end

  test "-1 day" do
    assert %{days: -1, microseconds: 0} == decode(0, -1, 0)
  end

  test "1 month" do
    assert %{months: 1, microseconds: 0} == decode(1, 0, 0)
  end

  test "-1 month" do
    assert %{months: -1, microseconds: 0} == decode(-1, 0, 0)
  end

  test "1 month, 1 day, 1 microsecond" do
    assert %{months: 1, days: 1, microseconds: 1} == decode(1, 1, 1)
  end
end
