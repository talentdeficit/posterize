defmodule :posterize_xt_date do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, [send: "date_send"]

  @pg_epoch :calendar.date_to_gregorian_days({ 2000, 1, 1 })
  
  @max_year 5874897
  @min_year -4713

  @common_era_start -1 * (:calendar.date_to_gregorian_days({ 1999, 1, 1 }) - 1)

  # shift all negative dates so that -1 BC is 4800 AD, -4713 BC is 88 AD and
  # -4401 is 400 AD so leap years line up
  @proleptic_year_adj 4801
  # after shifting years, unshift days to get postgres encoding
  @proleptic_day_adj :calendar.date_to_gregorian_days({ 4800, 1, 1 }) + @pg_epoch

  @infinity 2147483647
  @neg_infinity -2147483648

  def init(_), do: :undefined

  def encode(_) do
    quote location: :keep do
      { year, month, day } ->
        :posterize_xt_date.do_encode({ year, month, day })
      date when date == :infinity or date == :'-infinity' ->
        :posterize_xt_date.do_encode(date)
      other -> :posterize_xt_date.bad_date(other)
    end
  end

  def do_encode(:infinity), do: << 4 :: int32, @infinity :: int32 >>
  def do_encode(:'-infinity'), do: << 4 :: int32, @neg_infinity :: int32 >>
  def do_encode({ year, month, day } = date) when year >= @min_year and year < 0 and is_integer(month) and is_integer(day) do
    try do
      days = :calendar.date_to_gregorian_days({ year + @proleptic_year_adj, month, day })
      << 4 :: int32, (days - @proleptic_day_adj) :: int32 >>
    rescue
      _ in ErlangError -> bad_date(date)
    end
  end
  def do_encode({ year, month, day } = date) when year > 0 and year <= @max_year and is_integer(month) and is_integer(day) do
    try do
      date = :calendar.date_to_gregorian_days(date) - @pg_epoch
      << 4 :: int32, date :: int32 >>
    rescue
      _ in ErlangError -> bad_date(date)
    end
  end
  def do_encode(date), do: bad_date(date)

  def decode(_) do
    quote location: :keep do
      << 4 :: int32, days :: int32 >> ->
        :posterize_xt_date.do_decode(days)
    end
  end

  def do_decode(@infinity), do: :infinity
  def do_decode(@neg_infinity), do: :'-infinity'
  # dates get weird when dealing with BCE
  def do_decode(days) when days < @common_era_start do
    d = days + @proleptic_day_adj
    { y, m, d } = :calendar.gregorian_days_to_date(d)
    { y - @proleptic_year_adj, m, d }
  end
  def do_decode(days) do
    :calendar.gregorian_days_to_date(days + @pg_epoch)
  end

  def bad_date(date) do
    raise ArgumentError, Postgrex.Utils.encode_msg(
      date,
      "a date tuple (`{ Year, Month, Day }`) representing a valid date, the atom 'infinity' or the atom '-infinity'"
    )
  end
end
