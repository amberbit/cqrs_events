defmodule Cqrs.Events.ServerTest.AsyncHandler do
  use Cqrs.Events.AsyncHandler

  def handle_call(:messages_count, _from, state) do
    {:reply, state.messages_count, state}
  end

  def handle_event(message, state) do
    {:noreply, %{ state | messages_count: state.messages_count + 1 }}
  end
end

defmodule Cqrs.Events.ServerTest.SyncHandler do
  use Cqrs.Events.SyncHandler

  def handle_call(:messages_count, _from, state) do
    {:reply, state.messages_count, state}
  end

  def handle_event(message, state) do
    state = %{ state | messages_count: state.messages_count + 1 }
    {:reply, :ok, state}
  end
end

defmodule Cqrs.Events.ServerTest.SyncCrashingHandler do
  use Cqrs.Events.SyncHandler

  def handle_call(:messages_count, _from, state) do
    {:reply, state.messages_count, state}
  end

  def handle_event(message, state) do
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
  import ExUnit.CaptureIO

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
    {:ok, pid} = AsyncHandler.start_link("UserCreated", %{messages_count: 0})

    assert GenServer.call(pid, :messages_count) == 0

    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}

    assert GenServer.call(pid, :messages_count) == 1
  end

  test "should dispatch to sync events handlers" do
    {:ok, pid} = SyncHandler.start_link("UserCreated", %{messages_count: 0})

    assert GenServer.call(pid, :messages_count) == 0

    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}

    assert GenServer.call(pid, :messages_count) == 1
  end

  test "should not crash when sync handler crashes" do
    {:ok, pid} = SyncCrashingHandler.start_link("UserCreated", %{messages_count: 0})
    Process.unlink(pid) # so our test won't crash

    server_pid = Process.whereis(Server)

    Server.trigger "UserCreated", %{id: 1, name: "Jack Black", password: "nakatomi"}

    assert server_pid == Process.whereis(Server)
  end
end
