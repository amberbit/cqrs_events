defmodule Cqrs.Events.SyncHandler do
  defmacro __using__(_opts) do
    quote do
      use Cqrs.Events.BasicHandler

      def start_link(event_name, opts \\ %{}) do
        GenServer.start_link __MODULE__, Map.merge(opts, %{event_name: event_name, async: false}), []
      end
    end
  end
end
