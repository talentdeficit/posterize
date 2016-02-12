defmodule Posterize.Extensions.Interval do
  @moduledoc false
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension, send: "interval_send"

  @usec_per_second 1000000

  def encode(_, {{hour, min, sec}, days, months}, _, _)
  when days in -2147483647..2147483647 and months in -2147483647..2147483647 and hour in -23..23 and min in -59..59 and sec in -59..59 do
    time = :calendar.time_to_seconds({hour, min, sec})
    << time * @usec_per_second :: int64, days :: int32, months :: int32 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "interval")
  end

  def decode(_, << usec :: int64, days :: int32, months :: int32 >>, _, _) do
    secs = div(usec, @usec_per_second)
    {:calendar.seconds_to_time(secs), days, months}
  end

  def encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end