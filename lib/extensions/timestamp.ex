defmodule :posterize_xt_timestamp do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false

  @unix_epoch :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
  @gs_epoch :calendar.datetime_to_gregorian_seconds({{2000, 1, 1}, {0, 0, 0}})
  @usec_per_second 1000000

  def init(_), do: :undefined

  def matching(_),
    do: [type: "timestamp"]

  def format(_),
    do: :binary

  def encode(_) do
    quote location: :keep do
      {unit, count} when is_atom(unit) and is_integer(count) ->
        :posterize_xt_timestamp.do_encode(unit, count)
      count when is_integer(count) ->
        :posterize_xt_timestamp.do_encode(:native, count)
      other ->
        raise ArgumentError, Postgrex.Utils.encode_msg(other, "an integer time in native units or a `{Units, Count}` tuple")
    end
  end

  def decode(_) do
    quote location: :keep do
      <<8 :: int32, microsecs :: int64>> ->
        :posterize_xt_timestamp.do_decode(microsecs)
    end
  end

  def do_encode(unit, count) do
    seconds = :erlang.convert_time_unit(count, unit, :seconds)
    datetime = :calendar.gregorian_seconds_to_datetime(seconds + @unix_epoch)
    gregorian_seconds = :calendar.datetime_to_gregorian_seconds(datetime) - @gs_epoch
    <<8 :: int32, (gregorian_seconds * @usec_per_second) :: int64>>
  end

  def do_decode(microsecs) do
    adjustment = (@gs_epoch - @unix_epoch) * @usec_per_second
    :erlang.convert_time_unit(microsecs + adjustment, :micro_seconds, :native)
  end
end