defmodule Cqrs.Events.BasicHandler do
  defmacro __using__(_opts) do
    quote do
      @behaviour Cqrs.Events.Handler

      use GenServer

      def init(args) do
        #:gproc.reg({:p, :g, args.event_name}, %{async: args.async, mod: __MODULE__})
        :syn.join({args.event_name, args.async}, self())
        {:ok, args}
      end
    end
  end
end

