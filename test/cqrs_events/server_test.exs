defmodule Cqrs.Events.ServerTest do
  use ExUnit.Case
  alias Cqrs.Events.Server
  alias Cqrs.Events.Db

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

  test "should dispatch to events handlers"

  test "should dispatch to multiple events handlers in order of priority"

  test "should wait for synchronous handlers to finish before dispatching to next handler"

  test "should not wait for asynchronous handlers before dispatching to next handler"

  test "should return after all synchronous events handlers finished"
end
