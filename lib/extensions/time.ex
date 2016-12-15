defmodule :posterize_xt_time do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false

  def init(_), do: :undefined

  def matching(_),
    do: [type: "time"]

  def format(_),
    do: :binary

  def encode(_) do
    quote location: :keep do
      {unit, count} when is_atom(unit) and is_integer(count) ->
        :posterize_xt_time.do_encode(unit, count)
      count when is_integer(count) ->
        :posterize_xt_time.do_encode(:native, count)
      other ->
        raise ArgumentError, Postgrex.Utils.encode_msg(other, "an integer time in native units or a `{Units, Count}` tuple")
    end
  end

  def decode(_) do
    quote location: :keep do
      <<8 :: int32, microsecs :: int64>> ->
        :posterize_xt_time.do_decode(microsecs)
    end
  end

  def do_encode(unit, count) do
    usecs = :erlang.convert_time_unit(count, unit, :micro_seconds)
    <<8 :: int32, usecs :: int64>>
  end

  def do_decode(microsecs) do
    :erlang.convert_time_unit(microsecs, :micro_seconds, :native)
  end
end
