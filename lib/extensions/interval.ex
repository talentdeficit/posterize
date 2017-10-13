defmodule :posterize_xt_interval do
  @moduledoc false
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, send: "interval_send"

  def encode(_) do
    quote location: :keep do
      interval when is_map(interval) ->
        :posterize_xt_interval.do_encode(interval)

      other ->
        raise ArgumentError,
              Postgrex.Utils.encode_msg(
                other,
                "a map describing an interval in years, months, weeks, days, hours, minutes, seconds and/or microseconds"
              )
    end
  end

  def do_encode(interval) do
    months = Map.get(interval, :years, 0) * 12 + Map.get(interval, :months, 0)
    days = Map.get(interval, :weeks, 0) * 7 + Map.get(interval, :days, 0)

    microseconds =
      Map.get(interval, :hours, 0) * 60 * 60 * 1_000_000 +
        Map.get(interval, :minutes, 0) * 60 * 1_000_000 +
        Map.get(interval, :seconds, 0) * 1_000_000 + Map.get(interval, :microseconds, 0)

    <<16::int32, microseconds::int64, days::int32, months::int32>>
  end

  def decode(_) do
    quote location: :keep do
      <<16::int32, microseconds::int64, days::int32, months::int32>> ->
        :posterize_xt_interval.do_decode(months, days, microseconds)
    end
  end

  def do_decode(months, days, microseconds) do
    %{} |> maybe_months(months) |> maybe_days(days) |> Map.put(:microseconds, microseconds)
  end

  defp maybe_months(interval, 0), do: interval
  defp maybe_months(interval, months), do: Map.put(interval, :months, months)

  defp maybe_days(interval, 0), do: interval
  defp maybe_days(interval, days), do: Map.put(interval, :days, days)
end
