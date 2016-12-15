defmodule :posterize_xt_date do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false

  @gd_epoch :calendar.date_to_gregorian_days({2000, 1, 1})
  @max_year 5874897

  def init(_), do: :undefined

  def matching(_),
    do: [type: "date"]

  def format(_),
    do: :binary

  def encode(_) do
    quote location: :keep do
      {year, month, day} ->
        :posterize_xt_date.do_encode({year, month, day})
      other ->
        raise ArgumentError, Postgrex.Utils.encode_msg(other, "a date tuple (`{Year, Month, Day}`)")
    end
  end

  def decode(_) do
    quote location: :keep do
      <<4 :: int32, days :: int32>> ->
        :posterize_xt_date.do_decode(days)
    end
  end

  def do_encode(date) do
    date = :calendar.date_to_gregorian_days(date) - @gd_epoch
    <<4 :: int32, date :: int32>>
  end

  def do_decode(days) do
    IO.inspect days
    :calendar.gregorian_days_to_date(days + @gd_epoch)
  end
end
