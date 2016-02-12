defmodule :posterize_xt_date do
  @moduledoc """
  a posterize date extension compatible with the `calendar` module
  """
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension, send: "date_send"

  @gd_epoch :calendar.date_to_gregorian_days({2000, 1, 1})
  @date_max_year 5874897

  @doc """
  encodes the `calendar:date()` type into the postgres `date` type
  """
  def encode(_, {year, month, day}, _, _)
  when year <= @date_max_year and month in 1..12 and day in 1..31 do
    date = {year, month, day}
    << :calendar.date_to_gregorian_days(date) - @gd_epoch :: int32 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "date")
  end

  @doc """
  decodes a postgres `date` type into the `calendar:date()` type
  """
  def decode(_, << days :: int32 >>, _, _) do
    :calendar.gregorian_days_to_date(days + @gd_epoch)
  end

  defp encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end