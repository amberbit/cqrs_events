defmodule Cqrs.Events.Server do
  use GenServer
  require Logger
  alias Cqrs.Events.Handlers
  alias Cqrs.Events.Db

  import Moebius.DocumentQuery, only: [db: 1, insert: 2]

  # GenServer API
  def start_link(name) do
    GenServer.start_link(__MODULE__, %{}, [name: name])
  end

  # Public API

  def trigger(event, payload \\ %{}) do
    GenServer.call(__MODULE__, {:event, payload})

    find_handlers(event, true)
    |> Enum.each( &(cast_to_handler(&1, payload)) )

    find_handlers(event, false)
    |> Enum.each( &(call_handler(&1, payload)) )
  end

  defp find_handlers(event, async) do
    :gproc.lookup_values({:p, :g, event})
    |> Enum.filter( &(elem(&1, 1).async == async ) )
    |> Enum.map( &(elem(&1, 0)) )
  end

  defp cast_to_handler(handler_pid, payload) do
    GenServer.cast(handler_pid, %{payload: payload})
  end

  defp call_handler(handler_pid, payload) do
    try do
      GenServer.call(handler_pid, %{payload: payload})
    catch
      :exit, _ -> Logger.error "CQRS Event handler crashed:"
    end
  end

  # Private API

  def handle_call({event, payload}, _from, state) do
    db(:cqrs_events)
    |> insert(%{event: event, payload: payload})
    |> Db.run

    {:reply, :ok, state}
  end
end

