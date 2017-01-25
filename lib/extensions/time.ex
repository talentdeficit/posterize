defmodule :posterize_xt_time do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, [send: "time_send"]

  def init(opts) do
    case Keyword.get(opts, :units) do
      nil                       -> :native
      units when is_atom(units) -> units
    end
  end

  def encode(units) do
    quote location: :keep do
      time when is_integer(time) ->
        :posterize_xt_time.do_encode(unquote(units), time)
      other ->
        raise ArgumentError, Postgrex.Utils.encode_msg(
          other,
          "an integer representing time (default units: `native`)"
        )
    end
  end

  def do_encode(units, count) do
    usecs = :erlang.convert_time_unit(count, units, :micro_seconds)
    << 8 :: int32, usecs :: int64 >>
  end

  def decode(units) do
    quote location: :keep do
      << 8 :: int32, time :: int64 >> ->
        :posterize_xt_time.do_decode(unquote(units), time)
    end
  end

  def do_decode(units, time) do
    :erlang.convert_time_unit(time, :micro_seconds, units)
  end
end
