defmodule Mycelium.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MyceliumWeb.Telemetry,
      # TODO: Uncomment below to enable using database
      # Mycelium.Repo,
      {DNSCluster, query: Application.get_env(:mycelium, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mycelium.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Mycelium.Finch},
      # Start a worker by calling: Mycelium.Worker.start_link(arg)
      # {Mycelium.Worker, arg},
      # Start to serve requests, typically the last entry
      MyceliumWeb.Endpoint,
      MyceliumWeb.Presence,
      {DynamicSupervisor, name: Mycelium.SubserverSupervisor, strategy: :one_for_one, restart: :temporary},
      {Mycelium.Servers.SubserverManager, name: Mycelium.SubserverManger},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mycelium.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MyceliumWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
