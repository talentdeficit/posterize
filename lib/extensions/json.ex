defmodule :posterize_xt_jsx do
  @moduledoc """
  a posterize extension that supports the `json` and `jsonb` types
  
  this module uses the `jsx` json library and decodes json objects to
  maps
  """

  use Postgrex.BinaryExtension, [type: "json", type: "jsonb"]

  alias Postgrex.TypeInfo

  @doc """
  encodes atoms, binaries, integers, floats and maps and lists containing
  atoms, binaries, integers and floats to the postgres `json` and `jsonb`
  types
  """
  def encode(%TypeInfo{type: "json"}, term, _state, _),
    do: :jsx.encode(term)
  def encode(%TypeInfo{type: "jsonb"}, term, _state, _),
    do: <<1, :jsx.encode(term)::binary>>

  @doc """
  decodes the postgres `json` and `jsonb` types to  atoms, binaries,
  integers, floats and maps and lists containing atoms, binaries,
  integers and floats
  types
  """
  def decode(%TypeInfo{type: "json"}, json, _state, _),
    do: :jsx.decode(json, [:return_maps])
  def decode(%TypeInfo{type: "jsonb"}, <<1, json::binary>>, _state, _),
    do: :jsx.decode(json, [:return_maps])
end
