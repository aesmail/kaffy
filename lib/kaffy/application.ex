defmodule Kaffy.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Kaffy.Scheduler.Supervisor, []},
      Kaffy.Cache.Client
    ]

    opts = [strategy: :one_for_one, name: Kaffy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
