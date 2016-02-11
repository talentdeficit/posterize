defmodule Posterize.Extensions.EPGSQL.Time do
  @moduledoc false
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension, [send: "time_send", send: "timetz_send"]

  @usec_per_second 1000000

  def encode(_, {hour, min, sec}, _, _)
  when hour in 0..23 and min in 0..59 and sec >= 0.0 and sec < 60 do
    time = :calendar.time_to_seconds({hour, min, 0})
    usecs = :erlang.trunc((time + sec) * @usec_per_second)
    << usecs :: int64 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "time")
  end

  def decode(_, << microsecs :: int64 >>, _, _) do
    secs = div(microsecs, @usec_per_second)
    usecs = (rem(microsecs, @usec_per_second)) / @usec_per_second
    {hour, min, sec} = :calendar.seconds_to_time(secs)
    {hour, min, :erlang.float(sec) + usecs}
  end

  def encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end