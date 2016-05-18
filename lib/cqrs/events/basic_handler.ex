defmodule Cqrs.Events.BasicHandler do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      def init(args) do
        :gproc.reg({:p, :g, args.event_name}, %{async: args.async, mod: __MODULE__})
        {:ok, args}
      end
    end
  end
end

