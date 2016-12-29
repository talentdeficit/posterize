defmodule :posterize_xt_timestamp do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, [send: "timestamp_send"]

  @unix_epoch :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
  @gs_epoch :calendar.datetime_to_gregorian_seconds({{2000, 1, 1}, {0, 0, 0}})
  @adjustment :erlang.convert_time_unit(@gs_epoch - @unix_epoch, :seconds, :microsecond)

  @min_timestamp -211810204800000000
  @max_timestamp 9223371331201000000

  @infinity 9223372036854775807
  @neg_infinity -9223372036854775808

  def init(opts) do
    case Keyword.get(opts, :units) do
      nil                       -> :native
      units when is_atom(units) -> units
    end
  end

  def encode(units) do
    quote location: :keep do
      ts when is_integer(ts) or ts == :infinity or ts == :'-infinity' ->
        :posterize_xt_timestamp.do_encode(unquote(units), ts)
      other ->
        raise ArgumentError, Postgrex.Utils.encode_msg(
          other,
          "an integer representing time since unix epoch in utc"
        )
    end
  end

  def do_encode(_units, :infinity) do
      << 8 :: int32, @infinity :: int64 >>
  end
  def do_encode(_units, :'-infinity') do
      << 8 :: int32, @neg_infinity :: int64 >>
  end
  def do_encode(units, timestamp) do
    case :erlang.convert_time_unit(timestamp, units, :microsecond) - @adjustment do
      ts when ts >= @min_timestamp and ts <= @max_timestamp ->
        << 8 :: int32, ts :: int64 >>
      _ ->
        raise ArgumentError, "timestamp is outside postgres' allowable range"
    end
  end

  def decode(units) do
    quote location: :keep do
      << 8 :: int32, microsecs :: int64 >> ->
        :posterize_xt_timestamp.do_decode(unquote(units), microsecs)
    end
  end

  def do_decode(units, microsecs) do
    case microsecs do
      @neg_infinity -> :'-infinity'
      @infinity -> :infinity
      _ -> :erlang.convert_time_unit(microsecs + @adjustment, :microsecond, units)
    end
  end
end