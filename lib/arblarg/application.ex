defmodule Arblarg.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ArblargWeb.Telemetry,
      Arblarg.Repo,
      Arblarg.CacheSupervisor,
      {DNSCluster, query: Application.get_env(:arblarg, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Arblarg.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Arblarg.Finch},
      # Start to serve requests, typically the last entry
      ArblargWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Arblarg.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ArblargWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def application do
    [
      mod: {Arblarg.Application, []},
      extra_applications: [:logger, :runtime_tools, :httpoison, :hammer]
    ]
  end
end
