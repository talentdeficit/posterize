defmodule :posterize_xt_integer_time do
  @moduledoc """
  a posterize time extension compatible with the erlang system time apis
  """
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension, [send: "time_send", send: "timetz_send"]

  @doc """
  encodes erlang system time into the postgres `time` or `timetz` type
  """
  def encode(type_info, ns, types, opts) when is_integer(ns) do
    encode(type_info, {:native, ns}, types, opts)
  end
  def encode(_, {unit, ns}, _, _) when is_integer(ns) do
    usecs = :erlang.convert_time_unit(ns, unit, :micro_seconds)
    << usecs :: int64 >>
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "time")
  end

  @doc """
  decodes a postgres `time` or `time_tz` type into an erlang system time

  this always returns time in `native` units. use `erlang:convert_time_unit/3`
  to convert to other units
  """
  def decode(_, << microsecs :: int64 >>, _, _) do
    :erlang.convert_time_unit(microsecs, :micro_seconds, :native)
  end

  def encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end