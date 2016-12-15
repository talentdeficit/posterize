defmodule :posterize_xt_timetz do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false

  @usec_per_second 1000000
  @day (:calendar.time_to_seconds({23, 59, 59}) + 1) * @usec_per_second

  def init(_), do: :undefined

  def matching(_),
    do: [type: "timetz"]

  def format(_),
    do: :binary

  def encode(_) do
    quote location: :keep do
      {unit, count} when is_atom(unit) and is_integer(count) ->
        :posterize_xt_timetz.do_encode(unit, count)
      count when is_integer(count) ->
        :posterize_xt_timetz.do_encode(:native, count)
      other ->
        raise ArgumentError, Postgrex.Utils.encode_msg(other, "an integer time in native units or a `{Units, Count}` tuple")
    end
  end

  def decode(_) do
    quote location: :keep do
      <<12 :: int32, microsecs :: int64, tz :: int32>> ->
        :posterize_xt_timetz.do_decode(microsecs, tz)
    end
  end

  def do_encode(unit, count) do
    usecs = :erlang.convert_time_unit(count, unit, :micro_seconds)
    <<12 :: int32, usecs :: int64, 0 :: int32>>
  end

  def do_decode(microsecs, tz) do
    case microsecs + tz * @usec_per_second do
      adjusted when adjusted < 0 ->
        :erlang.convert_time_unit(@day + adjusted, :micro_seconds, :native)
      adjusted when adjusted < @day ->
        :erlang.convert_time_unit(adjusted, :micro_seconds, :native)
      adjusted ->
        :erlang.convert_time_unit(adjusted - @day, :micro_seconds, :native)
    end
  end
end