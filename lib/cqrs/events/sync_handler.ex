defmodule Cqrs.Events.SyncHandler do
  defmacro __using__(_opts) do
    quote do
      use Cqrs.Events.BasicHandler

      def start_link(event_name, opts \\ %{}) do
        GenServer.start_link __MODULE__, Map.merge(opts, %{event_name: event_name, async: false}), []
      end

      def handle_info({:syn_multi_call, caller_pid, message}, state) do
        {:reply, reply_value, state} = handle_event(message, state)
        :syn.multi_call_reply(caller_pid, reply_value)
        {:noreply, state}
      end
    end
  end
end
