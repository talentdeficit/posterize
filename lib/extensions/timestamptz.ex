defmodule :posterize_xt_timestamptz do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, [send: "timestamptz_send"]

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

  def decode(units) do
    quote location: :keep do
      << 8 :: int32, microsecs :: int64 >> ->
        :posterize_xt_timestamp.do_decode(unquote(units), microsecs)
    end
  end
end