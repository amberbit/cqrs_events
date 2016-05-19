defmodule Cqrs.Events.Handler do
  @callback handle_event(any, any) :: any
end

