defmodule :posterize_xt_jsonb do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, [send: "jsonb_send"]

  def init(opts) do
    Keyword.get(opts, :decode_binary, :copy)
  end

  def encode(_) do
    quote location: :keep do
      map ->
        data = :jsx.encode(map)
        [<<(IO.iodata_length(data)+1) :: int32, 1>> | data]
    end
  end

  def decode(:copy) do
    quote location: :keep do
      <<len :: int32, data :: binary-size(len)>> ->
        <<1, json :: binary>> = data
        copy = :binary.copy(json)
        :jsx.decode(copy, [:return_maps])
    end
  end
  def decode(:reference) do
    quote location: :keep do
      <<len :: int32, data :: binary-size(len)>> ->
        <<1, json :: binary>> = data
        :jsx.decode(json, [:return_maps])
    end
  end
end
