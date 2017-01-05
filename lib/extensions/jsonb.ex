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
      json when is_binary(json) ->
        [<<(IO.iodata_length(json) + 1) :: int32, 1>> | json]
    end
  end

  def decode(:copy) do
    quote location: :keep do
      <<len :: int32, data :: binary-size(len)>> ->
        <<1, json :: binary>> = data
        :binary.copy(json)
    end
  end
  def decode(:reference) do
    quote location: :keep do
      <<len :: int32, data :: binary-size(len)>> ->
        <<1, json :: binary>> = data
        json
    end
  end
end
