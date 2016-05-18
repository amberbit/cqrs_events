defmodule Cqrs.Events.Server do
  use GenServer
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
  end

  # Private API

  def handle_call({event, payload}, _from, state) do
    db(:cqrs_events)
    |> insert(%{event: event, payload: payload})
    |> Db.run

    {:reply, :ok, state}
  end
end

