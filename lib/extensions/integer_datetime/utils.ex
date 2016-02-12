defmodule Posterize.Extensions.Integer.Utils do
  @moduledoc false
  
  def stack do
    [{Posterize.Extensions.Integer.Date, []},
     {Posterize.Extensions.Integer.Time, []},
     {Posterize.Extensions.Integer.DateTime, []},
     {Posterize.Extensions.Integer.Interval, []}]
  end
end
