defmodule Posterize.Extensions.Integer.Date do
  @moduledoc false
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension, send: "date_send"

  @unix_epoch :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
  @gd_epoch :calendar.date_to_gregorian_days({2000, 1, 1})

  def encode(type_info, ns, types, opts) when is_integer(ns) do
    encode(type_info, {:native, ns}, types, opts)
  end
  def encode(_, {unit, ns}, _, _) when is_integer(ns) do
    seconds = :erlang.convert_time_unit(ns, unit, :seconds)
    {date, _} = :calendar.gregorian_seconds_to_datetime(seconds + @unix_epoch)
    << :calendar.date_to_gregorian_days(date) - @gd_epoch :: int32 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "date")
  end

  def decode(_, << days :: int32 >>, _, _) do
    date = :calendar.gregorian_days_to_date(days + @gd_epoch)
    seconds = :calendar.datetime_to_gregorian_seconds({date, {0, 0, 0}}) - @unix_epoch
    :erlang.convert_time_unit(seconds, :seconds, :native)
  end

  def encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end