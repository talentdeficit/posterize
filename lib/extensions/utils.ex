defmodule :posterize_xt_datetime_utils do
  @moduledoc false
  
  def stack do
    [{:posterize_xt_date, []},
     {:posterize_xt_time, []},
     {:posterize_xt_datetime, []},
     {:posterize_xt_interval, []}]
  end
end
