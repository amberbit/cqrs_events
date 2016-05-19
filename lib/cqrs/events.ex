defmodule Cqrs.Events do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Cqrs.Events.Worker, [arg1, arg2, arg3]),
      worker(Cqrs.Events.Db, [Moebius.get_connection(:cqrs_events)]),
      worker(Cqrs.Events.Server, [Cqrs.Events.Server]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options

    :syn.init()

    opts = [strategy: :one_for_one, name: Cqrs.Events.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
