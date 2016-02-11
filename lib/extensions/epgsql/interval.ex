defmodule Posterize.Extensions.EPGSQL.Interval do
  @moduledoc false
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension, send: "interval_send"

  @usec_per_second 1000000

  def encode(_, {{hour, min, sec}, days, months}, _, _)
  when days >= 0 and is_integer(days) and months >= 0 and is_integer(months) and hour in 0..23 and min in 0..59 and sec >= 0.0 and sec < 60 do
    microsecs = :erlang.trunc((:calendar.time_to_seconds({hour, min, 0}) + sec) * @usec_per_second)
    << microsecs :: int64, days :: int32, months :: int32 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "interval")
  end

  def decode(_, << usec :: int64, days :: int32, months :: int32 >>, _, _) do
    secs = div(usec, @usec_per_second)
    usecs = rem(usec, @usec_per_second) / @usec_per_second
    {hour, min, sec} = :calendar.seconds_to_time(secs)
    {{hour, min, sec + usecs}, days, months}
  end

  def encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end