defmodule Cqrs.Events.ServerTest.AsyncHandler do
  use Cqrs.Events.AsyncHandler

  def handle_event(payload, _config) do
    Counters.increment __MODULE__
  end
end

defmodule Cqrs.Events.ServerTest.SyncHandler do
  use Cqrs.Events.SyncHandler

  def handle_event(payload, _config) do
    Counters.increment __MODULE__
  end
end

defmodule Cqrs.Events.ServerTest.SyncCrashingHandler do
  use Cqrs.Events.SyncHandler

  def handle_event(payload, _config) do
    Counters.increment __MODULE__
    1 / 0
  end
end

defmodule Counters do
  use GenServer

  def start_link(name \\ Counters) do
    GenServer.start_link __MODULE__, %{}, name: name
  end

  def clear do
    GenServer.cast __MODULE__, :clear
  end

  def get(key) do
    GenServer.call __MODULE__, {:get, key}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, state[key] || 0, state}
  end

  def increment(key) do
    GenServer.cast(__MODULE__, {:increment, key})
  end

  def handle_cast({:increment, key}, state) do
    count = (state[key] || 0) + 1

    {:noreply, Map.merge(state, %{key => count})}
  end

  def handle_cast :clear, _state do
    {:noreply, %{}}
  end
end

defmodule Cqrs.Events.ServerTest do
  use ExUnit.Case
  alias Cqrs.Events.Server
  alias Cqrs.Events.Db
  alias Cqrs.Events.ServerTest.AsyncHandler
  alias Cqrs.Events.ServerTest.SyncHandler
  alias Cqrs.Events.ServerTest.SyncCrashingHandler
  import ExUnit.CaptureIO

  Moebius.DocumentQuery

  setup do
    Db.run "drop table if exists \"cqrs_events\""
    Db.create_document_table :cqrs_events
    Counters.start_link
    :ok
  end

  def count_events do
    [%{count: count}] = Db.run "select count(*) from cqrs_events"
    count
  end

  test "should persist all events sent" do
    count_before = count_events
    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}
    assert count_before < count_events
  end

  test "should dispatch to async events handlers" do
    {:ok, pid} = AsyncHandler.start_link("UserCreated", %{messages_count: 0})

    assert Counters.get(AsyncHandler) == 0

    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}

    assert Counters.get(AsyncHandler) == 1
  end

  test "should dispatch to sync events handlers" do
    {:ok, pid} = SyncHandler.start_link("UserCreated", %{messages_count: 0})

    assert Counters.get(SyncHandler) == 0

    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}

    assert Counters.get(SyncHandler) == 1
  end

  test "should not crash when sync handler crashes" do
    {:ok, pid} = SyncCrashingHandler.start_link("UserCreated", %{messages_count: 0})

    Process.unlink(pid) # so our test won't crash

    server_pid = Process.whereis(Server)

    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}

    assert server_pid == Process.whereis(Server)
  end
end

