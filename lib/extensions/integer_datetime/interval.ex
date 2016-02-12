defmodule :posterize_xt_integer_interval do
  @moduledoc """
  a posterize interval extension compatible with erlang system time apis
  """
  import Postgrex.BinaryUtils
  use Postgrex.BinaryExtension, send: "interval_send"

  ## when using integer time interval can only encode/decode microsecond
  ## components of the time and will never encode days/months and will
  ## error if trying to decode an interval field with days/months

  @max_usec 9223372036854775807
  @usec_per_second 1000000

  @doc """
  encodes erlang system time into the postgres `interval`
  type
  """
  def encode(type_info, ns, types, opts) when is_integer(ns) do
    encode(type_info, {:native, ns}, types, opts)
  end
  def encode(type_info, {unit, ns}, _, _) when is_integer(ns) do
    case :erlang.convert_time_unit(ns, unit, :micro_seconds) do
      usecs when usecs in 0..@max_usec ->
        << usecs :: int64, 0 :: int32, 0 :: int32 >>
      _ ->
        raise ArgumentError, encode_msg(type_info, {unit, ns}, "interval")
    end
  end
  def encode(type_info, value, _, _) do
    raise ArgumentError, encode_msg(type_info, value, "interval")
  end

  @doc """
  decodes a postgres `interval` type into an erlang system time

  this always returns time in `native` units. use `erlang:convert_time_unit/3`
  to convert to other units
  """
  def decode(_, << usecs :: int64, 0 :: int32, 0 :: int32 >>, _, _) do
    :erlang.convert_time_unit(usecs, :micro_seconds, :native)
  end
  def decode(type_info, value, types, _) do
    raise ArgumentError, encode_msg(type_info, value, types)
  end

  def encode_msg(%Postgrex.TypeInfo{type: type}, observed, expected) do
    "Postgrex expected #{expected} that can be encoded/cast to " <>
    "type #{inspect type}, got #{inspect observed}. Please make sure the " <>
    "value you are passing matches the definition in your table or in your " <>
    "query or convert the value accordingly."
  end
end