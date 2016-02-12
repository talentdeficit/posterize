defmodule :posterize_xt_integer_utils do
  @moduledoc false
  
  def stack do
    [{:posterize_xt_integer_date, []},
     {:posterize_xt_integer_time, []},
     {:posterize_xt_integer_datetime, []},
     {:posterize_xt_integer_interval, []}]
  end
end
