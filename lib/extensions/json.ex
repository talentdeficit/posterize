defmodule :posterize_xt_json do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, [send: "json_send"]

  def init(opts) do
    Keyword.get(opts, :decode_binary, :copy)
  end

  def encode(_) do
    quote location: :keep do
      map ->
        data = :jsx.encode(map)
        [<<IO.iodata_length(data) :: int32>> | data]
    end
  end

  def decode(:copy) do
    quote location: :keep do
      <<len :: int32, json :: binary-size(len)>> ->
        json
        |> :binary.copy()
        |> :jsx.decode([:return_maps])
    end
  end
  def decode(:reference) do
    quote location: :keep do
      <<len :: int32, json :: binary-size(len)>> ->
        :jsx.decode(json, [:return_maps])
    end
  end
end
