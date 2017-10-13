defmodule :posterize_xt_json do
  @moduledoc false
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false
  use Postgrex.BinaryExtension, send: "json_send"

  def init(opts) do
    Keyword.get(opts, :decode_binary, :copy)
  end

  def encode(_) do
    quote location: :keep do
      json when is_binary(json) ->
        [<<IO.iodata_length(json)::int32>> | json]
    end
  end

  def decode(:copy) do
    quote location: :keep do
      <<len::int32, json::binary-size(len)>> ->
        json |> :binary.copy()
    end
  end

  def decode(:reference) do
    quote location: :keep do
      <<len::int32, json::binary-size(len)>> ->
        json
    end
  end
end
