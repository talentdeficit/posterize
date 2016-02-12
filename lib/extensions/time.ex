defmodule Posterize.Extensions.Time do
  @moduledoc false
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension, [send: "time_send", send: "timetz_send"]

  @usec_per_second 1000000

  def encode(_, {hour, min, sec}, _, _)
  when hour in 0..23 and min in 0..59 and sec in 0..59 do
    time = :calendar.time_to_seconds({hour, min, sec})
    << time * @usec_per_second :: int64 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "time")
  end

  def decode(_, << microsecs :: int64 >>, _, _) do
    secs = div(microsecs, @usec_per_second)
    :calendar.seconds_to_time(secs)
  end

  defp encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end