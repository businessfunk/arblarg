defmodule Arblarg.CacheSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Initialize the ETS cache
    Arblarg.Temporal.start_cache()

    # No children needed, just initializing the cache
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
end
