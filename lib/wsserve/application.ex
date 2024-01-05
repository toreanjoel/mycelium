defmodule Wsserve.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WsserveWeb.Telemetry,
      # TODO: Uncomment below to enable using database
      # Wsserve.Repo,
      {DNSCluster, query: Application.get_env(:wsserve, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Wsserve.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Wsserve.Finch},
      # Start a worker by calling: Wsserve.Worker.start_link(arg)
      # {Wsserve.Worker, arg},
      # Start to serve requests, typically the last entry
      WsserveWeb.Endpoint,
      WsserveWeb.Presence,
      {DynamicSupervisor, name: Wsserve.SubserverSupervisor, strategy: :one_for_one, restart: :temporary},
      {Wsserve.Servers.SubserverManager, name: Wsserve.SubserverManger},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wsserve.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WsserveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
