defmodule :posterize_xt_range do
  @moduledoc false
  import Postgrex.BinaryUtils, warn: false
  use Bitwise, only_operators: true
  @behaviour Postgrex.SuperExtension

  @empty << 1 >>

  def init(_), do: nil

  def matching(_), do: [send: "range_send"]

  def format(_), do: :super_binary

  def oids(%Postgrex.TypeInfo{base_type: base_oid}, _) do
    [base_oid]
  end

  def encode(_) do
    quote location: :keep do
      :empty, [_oid], [_type] -> :posterize_xt_range.do_encode(:empty)
      range, [oid], [type] ->
        bounds = Map.get(range, :bounds, :'[)')
        up = Map.get(range, :upper, @null)
        low = Map.get(range, :lower, @null)
        # encode_value/2 defined by TypeModule
        upper = encode_value(up, type)
        lower = encode_value(low, type)
        :posterize_xt_range.do_encode(upper, lower, bounds)
      other, _, _ ->
        raise ArgumentError, Postgrex.Utils.encode_msg(other, "a map describing a postgres range")
    end
  end

  def do_encode(:empty), do: @empty
  def do_encode(<< -1 :: int32 >>, << -1 :: int32 >>, bounds) do
    flags = encode_flags(:empty, :empty, bounds)
    [ << 1 :: int32 >> | flags ]
  end
  def do_encode(<< -1 :: int32 >>, lower, bounds) do
    flags = encode_flags(:empty, lower, bounds)
    [ << (IO.iodata_length(lower) + 1) :: int32 >>, flags | lower ]
  end
  def do_encode(upper, << -1 :: int32 >>, bounds) do
    flags = encode_flags(upper, :empty, bounds)
    [ << (IO.iodata_length(upper) + 1) :: int32 >>, flags | upper ]
  end
  def do_encode(upper, lower, bounds) do
    flags = encode_flags(upper, lower, bounds)
    [ << (IO.iodata_length([ lower | upper ]) + 1) :: int32 >>, flags | [ lower | upper ] ]
  end

  defp encode_flags(:empty, :empty, _bounds) do
    << 0 :: 3, 1 :: 1, 1 :: 1, 0 :: 1, 0 :: 1, 0 :: 1 >>
  end
  defp encode_flags(:empty, _lower, bounds) do
    { lower_inc, upper_inc } = encode_bounds(bounds)
    << 0 :: 3, 1 :: 1, 0 :: 1, upper_inc :: 1, lower_inc :: 1, 0 :: 1 >>
  end
  defp encode_flags(_upper, :empty, bounds) do
    { lower_inc, upper_inc } = encode_bounds(bounds)
    << 0 :: 3, 0 :: 1, 1 :: 1, upper_inc :: 1, lower_inc :: 1, 0 :: 1 >>
  end
  defp encode_flags(_upper, _lower, bounds) do
    { lower_inc, upper_inc } = encode_bounds(bounds)
    << 0 :: 3, 0 :: 1, 0 :: 1, upper_inc :: 1, lower_inc :: 1, 0 :: 1 >>      
  end

  defp encode_bounds(:'[]'), do: { 1, 1 }
  defp encode_bounds(:'[)'), do: { 1, 0 }
  defp encode_bounds(:'(]'), do: { 0, 1 }
  defp encode_bounds(:'()'), do: { 0, 0 }

  def decode(_) do
    quote location: :keep do
      << length :: int32, binary :: binary-size(length) >>, [oid], [type] ->
        << flags :: binary-size(1), data :: binary >> = binary
        # decode_list/2 defined by TypeModule
        elements = decode_list(data, type)
        :posterize_xt_range.do_decode(flags, elements)
    end
  end

  def do_decode(flags, elements) do
    case empty?(flags) do
      true  -> :empty
      false -> %{} |> upper(elements, flags) |> lower(elements, flags) |> bounds(flags)
    end
  end

  defp upper(range, elements, flags) do
    case upper_infinity?(flags) do
      true  -> range
      false -> Map.put(range, :upper, hd(elements))
    end
  end

  defp lower(range, elements, flags) do
    case lower_infinity?(flags) do
      true  -> range
      false -> Map.put(range, :lower, hd(Enum.reverse(elements)))
    end
  end

  defp bounds(range, flags) do
    bounds = case { lower_inclusive?(flags), upper_inclusive?(flags) } do
      { true, true }   -> :'[]'
      { true, false }  -> :'[)'
      { false, true }  -> :'(]'
      { false, false } -> :'()'
    end
    Map.put(range, :bounds, bounds) 
  end

  defp upper_infinity?(<< _ :: 3, 1 :: 1, _ :: 4 >>), do: true
  defp upper_infinity?(_), do: false

  defp lower_infinity?(<< _ :: 4, 1 :: 1, _ :: 3 >>), do: true
  defp lower_infinity?(_), do: false

  defp upper_inclusive?(<< _ :: 5, 1 :: 1, _ :: 2 >>), do: true
  defp upper_inclusive?(_), do: false

  defp lower_inclusive?(<< _ :: 6, 1 :: 1, _ :: 1 >>), do: true
  defp lower_inclusive?(_), do: false

  defp empty?(<< _ :: 7, 1 :: 1 >>), do: true
  defp empty?(_), do: false
end