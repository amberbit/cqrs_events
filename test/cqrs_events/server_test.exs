defmodule Cqrs.Events.ServerTest.AsyncHandler do
  use GenServer

  def start_link(event_name) do
    GenServer.start_link __MODULE__, %{event_name: event_name, async: true, messages_count: 0}, []
  end

  def init(args) do
    :gproc.reg({:p, :g, args.event_name}, %{async: args.async, mod: __MODULE__})
    {:ok, args}
  end

  def handle_call(:messages_count, _from, state) do
    {:reply, state.messages_count, state}
  end

  def handle_cast(message, state) do
    {:noreply, %{ state | messages_count: state.messages_count + 1 }}
  end
end

defmodule Cqrs.Events.ServerTest.SyncHandler do
  use GenServer

  def start_link(event_name) do
    GenServer.start_link __MODULE__, %{event_name: event_name, async: false, messages_count: 0}, []
  end

  def init(args) do
    :gproc.reg({:p, :g, args.event_name}, %{async: args.async, mod: __MODULE__})
    {:ok, args}
  end

  def handle_call(:messages_count, _from, state) do
    {:reply, state.messages_count, state}
  end

  def handle_call(_message, _from, state) do
    {:reply, :ok, %{ state | messages_count: state.messages_count + 1 }}
  end
end

defmodule Cqrs.Events.ServerTest.SyncCrashingHandler do
  use GenServer

  def start_link(event_name) do
    GenServer.start_link __MODULE__, %{event_name: event_name, async: false, messages_count: 0}, []
  end

  def init(args) do
    :gproc.reg({:p, :g, args.event_name}, %{async: args.async, mod: __MODULE__})
    {:ok, args}
  end

  def handle_call(:messages_count, _from, state) do
    {:reply, state.messages_count, state}
  end

  def handle_call(_message, _from, state) do
    1 / 0
    {:reply, :ok, %{ state | messages_count: state.messages_count + 1 }}
  end
end

defmodule Cqrs.Events.ServerTest do
  use ExUnit.Case
  alias Cqrs.Events.Server
  alias Cqrs.Events.Db
  alias Cqrs.Events.ServerTest.AsyncHandler
  alias Cqrs.Events.ServerTest.SyncHandler
  alias Cqrs.Events.ServerTest.SyncCrashingHandler

  Moebius.DocumentQuery

  setup do
    Db.run "drop table if exists \"cqrs_events\""
    Db.create_document_table :cqrs_events
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
    {:ok, pid} = AsyncHandler.start_link("UserCreated")

    assert GenServer.call(pid, :messages_count) == 0

    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}

    assert GenServer.call(pid, :messages_count) == 1
  end

  test "should dispatch to sync events handlers" do
    {:ok, pid} = SyncHandler.start_link("UserCreated")

    assert GenServer.call(pid, :messages_count) == 0

    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}

    assert GenServer.call(pid, :messages_count) == 1
  end

  test "should not crash when sync handler crashes" do
    {:ok, pid} = SyncCrashingHandler.start_link("UserCreated")
    Process.unlink(pid) # so our test won't crash

    server_pid = Process.whereis(Server)

    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}

    assert server_pid == Process.whereis(Server)
  end
end
