defmodule Posterize.Extensions.DateTime do
  @moduledoc false
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension,
    [send: "timestamp_send", send: "timestamptz_send"]

  @gs_epoch :calendar.datetime_to_gregorian_seconds({{2000, 1, 1}, {0, 0, 0}})
  @timestamp_max_year 294276
  @usec_per_second 1000000

  def encode(_, {{year, month, day}, {hour, min, sec}}, _, _)
  when year <= @timestamp_max_year and month in 1..12 and day in 1..31 and hour in 0..23 and min in 0..59 and sec in 0..59 do
    datetime = {{year, month, day}, {hour, min, sec}}
    gregorian_seconds = :calendar.datetime_to_gregorian_seconds(datetime) - @gs_epoch
    << gregorian_seconds * @usec_per_second :: int64 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "datetime")
  end

  def decode(_, << microsecs :: int64 >>, _, _) do
    secs = div(microsecs, @usec_per_second)
    :calendar.gregorian_seconds_to_datetime(secs + @gs_epoch)
  end

  defp encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end