defmodule :posterize_xt_integer_datetime do
  @moduledoc """
  a posterize datetime extension compatible with erlang system time apis
  """
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension,
    [send: "timestamp_send", send: "timestamptz_send"]

  @unix_epoch :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
  @gs_epoch :calendar.datetime_to_gregorian_seconds({{2000, 1, 1}, {0, 0, 0}})
  @usec_per_second 1000000

  @doc """
  encodes erlang system time into the postgres `timestamp`
  or `timestamp_tz` type
  """
  def encode(type_info, ns, types, opts) when is_integer(ns) do
    encode(type_info, {:native, ns}, types, opts)
  end
  def encode(_, {units, ns}, _, _) when is_integer(ns) do
    seconds = :erlang.convert_time_unit(ns, units, :seconds)
    datetime = :calendar.gregorian_seconds_to_datetime(seconds + @unix_epoch)
    gregorian_seconds = :calendar.datetime_to_gregorian_seconds(datetime) - @gs_epoch
    << gregorian_seconds * @usec_per_second :: int64 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "datetime")
  end

  @doc """
  decodes a postgres `timestamp` or `timestamp_tz` type into erlang
  system time

  this always returns time in `native` units. use `erlang:convert_time_unit/3`
  to convert to other units
  """
  def decode(_, << microsecs :: int64 >>, _, _) do
    adjustment = (@gs_epoch - @unix_epoch) * @usec_per_second
    :erlang.convert_time_unit(microsecs + adjustment, :micro_seconds, :native)
  end

  def encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end