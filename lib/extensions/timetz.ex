defmodule :posterize_xt_timetz do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, [send: "timetz_send"]

  def init(opts) do
    case Keyword.get(opts, :units) do
      nil                       -> :native
      units when is_atom(units) -> units
    end
  end

  def encode(units) do
    quote location: :keep do
      {time, offset} when is_integer(time) and is_integer(offset) ->
        :posterize_xt_timetz.do_encode(unquote(units), time, offset)
      time when is_integer(time) ->
        :posterize_xt_timetz.do_encode(unquote(units), time, 0)
      other ->
        raise ArgumentError, Postgrex.Utils.encode_msg(
          other,
          "an integer representing time (default units: `native`) or a tuple of a time and an offset (in the same units)"
        )
    end
  end

  def do_encode(units, time, offset) do
    tusecs = :erlang.convert_time_unit(time, units, :micro_seconds)
    osecs = :erlang.convert_time_unit(offset, units, :seconds)
    << 12 :: int32, tusecs :: int64, osecs :: int32 >>
  end

  def decode(units) do
    quote location: :keep do
      << 12 :: int32, time :: int64, offset :: int32 >> ->
        :posterize_xt_timetz.do_decode(unquote(units), time, offset)
    end
  end

  def do_decode(units, time, offset) do
    { :erlang.convert_time_unit(time, :micro_seconds, units),
      :erlang.convert_time_unit(offset, :seconds, units)
    }
  end
end
