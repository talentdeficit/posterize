defmodule :posterize_xt_interval do
  @moduledoc """
  a posterize interval extension

  intervals are represented by a `{calendar:time(), days, months}` tuple
  """
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension, send: "interval_send"

  @usec_per_second 1000000

  @doc """
  encodes a `{calendar:time(), days, month}` tuple into the postgres `interval`
  type

  any component of an interval can be positive or negative. a net negative interval
  represents a negative adjustment to a timestamp
  """
  def encode(_, {{hour, min, sec}, days, months}, _, _)
  when days in -2147483647..2147483647 and months in -2147483647..2147483647 and hour in -23..23 and min in -59..59 and sec in -59..59 do
    time = :calendar.time_to_seconds({hour, min, sec})
    << time * @usec_per_second :: int64, days :: int32, months :: int32 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "interval")
  end

  @doc """
  decodes a postgres `interval` type into a `{calendar:time(), days, months}` tuple

  any component of an interval can be positive or negative. a net negative interval
  represents a negative adjustment to a timestamp
  """
  def decode(_, << usec :: int64, days :: int32, months :: int32 >>, _, _) do
    secs = div(usec, @usec_per_second)
    {:calendar.seconds_to_time(secs), days, months}
  end

  defp encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end