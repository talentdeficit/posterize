defmodule :posterize_xt_float4 do
  @moduledoc false
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, send: "float4send"

  def encode(_) do
    quote location: :keep do
      n when is_number(n) ->
        << 4 :: int32, n :: float32 >>
      :NaN ->
        << 4 :: int32, 0 :: 1, 255, 1 :: 1, 0 :: 22 >>
      :infinity ->
        << 4 :: int32, 0 :: 1, 255, 0 :: 23 >>
      :'-infinity' ->
        << 4 :: int32, 1 :: 1, 255, 0 :: 23 >>
      other ->
        raise ArgumentError, Postgrex.Utils.encode_msg(other, "a float")
    end
  end

  def decode(_) do
    quote location: :keep do
      << 4 :: int32, 0 :: 1, 255, 0 :: 23 >> -> :infinity
      << 4 :: int32, 1 :: 1, 255, 0 :: 23 >> -> :'-infinity'
      << 4 :: int32, _ :: 1, 255, _ :: 23 >> -> :NaN
      << 4 :: int32, float :: float32 >>     -> float
    end
  end
end
