defmodule Posterize.Extensions.EPGSQL.DateTime do
  @moduledoc false
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension,
    [send: "timestamp_send", send: "timestamptz_send"]

  @gs_epoch :calendar.datetime_to_gregorian_seconds({{2000, 1, 1}, {0, 0, 0}})
  @timestamp_max_year 294276
  @usec_per_second 1000000

  def encode(_, {{year, month, day}, {hour, min, sec}}, _, _)
  when year <= @timestamp_max_year and hour in 0..23 and min in 0..59 and sec >= 0.0 and sec < 60 do
    datetime = {{year, month, day}, {hour, min, 0}}
    gregorian_seconds = :calendar.datetime_to_gregorian_seconds(datetime) - @gs_epoch
    usecs = :erlang.trunc((gregorian_seconds + sec) * @usec_per_second)
    << usecs :: int64 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "datetime")
  end

  def decode(_, << microsecs :: int64 >>, _, _) do
    secs = div(microsecs, @usec_per_second)
    usecs = (rem(microsecs, @usec_per_second)) / @usec_per_second
    {date, {hour, min, sec}} = :calendar.gregorian_seconds_to_datetime(secs + @gs_epoch)
    {date, {hour, min, sec + usecs}}
  end
  
  def encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end