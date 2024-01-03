defmodule Wsserve.Servers.SubserverManager do
  @moduledoc """
    Server Manager that is used to request crud operations against the servers
    and their proess information and system level lifecycle.
  """
  use GenServer
  require Logger
  alias Wsserve.SubserverSupervisor
  alias Wsserve.Servers.Subserver

  def start_link(args \\ %{}) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_state) do
    # here we make sure we init this with the running serer details
    init_running_servers()
    # TODO: potentially move to separate supervised server and make a client function to delete old
    garbage_collection_job()

    {:ok,
     %{
       servers: %{},
       refs: %{}
     }}
  end

  # Get server state curr in memory
  def handle_call(:get_servers, _from, state) do
    {:reply, Map.get(state, :servers), state}
  end

  # Get ref state curr in memory
  def handle_call(:get_server_refs, _from, state) do
    {:reply, Map.get(state, :refs), state}
  end

  # Create sub server
  def handle_call(:create, _from, state) do
    {status, _} = request_create_server()
    case status do
      :ok ->
        {:reply, state, state}
      _ ->
        Logger.error("There was a problem creating the server")
        {:reply, "There was a problem creating the server", state}
    end
  end

  # add ref to process and pid

  # delete a sub server

  # remove reference to process and pid

  # handle info to listen for crashes on sub servers

  # clear relevant process ref and pid if crash

  def handle_info({:server_config, %{id: server_id, pid: server_pid}}, state) do
    IO.inspect("server created event")
    # we start monitoring the process for other messages
    # we get a ref that when things crash we need to use to cleanup manager state
    ref = Process.monitor(server_pid)
    added_ref = Map.put(state.refs, ref, server_id)
    updated_state_w_refs = Map.put(state, :refs, added_ref)

    # add the process inder the server
    added_server = Map.put(updated_state_w_refs.servers, server_id, server_pid)
    updated_state = Map.put(state, :servers, added_server)
    {:noreply, updated_state}
  end

  # handling other massages that we dont know about yet
  def handle_info({event, ref, _, _, data}, state) do
    case event do
      :DOWN ->
        #TODO: remove the old from the list as it was killed
        # get the process prev state info
        {_, [{_, _, [_, _, prev_process_state], _}, _, _, _]} = data
        # restart a new instance with last known data
        IO.inspect(data)
        {status, _} = request_create_server(prev_process_state)
        case status do
          :ok ->
            Logger.info("Successfully revived crashed server data with last known data")
          _ ->
            Logger.error("There was a problem creating the server (recreate from falling)")
        end
      _ ->
        Logger.error("Something happened with a server")
        IO.inspect(%{
          event: event,
          ref: ref
        })
    end

    {:noreply, state}
  end

  # handling other massages that we dont know about yet
  def handle_info(:garbage_collect, state) do
    IO.inspect("collect garbage time!")
    garbage_collection_job()
    servers = DynamicSupervisor.which_children(SubserverSupervisor)
    IO.inspect("servers")
    IO.inspect(servers)
    IO.inspect(state)
    # case GenServer.whereis()
    {:noreply, state}
  end

  # Catch all at the end for mssages
  # handling other massages that we dont know about yet
  def handle_info(_event, state) do
    IO.inspect("Non handled process messages")
    {:noreply, state}
  end

  # The job that will tick and cleanup old processes
  defp garbage_collection_job() do
    Process.send_after(self(), :garbage_collect, 60_000) # cleanup every 15min ideally
  end

  # init function that if this were to go down and back up it initialized with running servers
  defp init_running_servers do
    servers = DynamicSupervisor.which_children(SubserverSupervisor)

    if !Enum.empty?(servers) do
      Enum.each(servers, fn {_, server_pid, _, _} ->
        # request that the servers tell this manager their config details
        send(server_pid, {:request_config, self()})
      end)
    end
    # we do nothing if there are no servers
  end

  # here we request to make a new child sercer
  defp request_create_server(payload \\ %{}) do
    init_state = %{
      manager_pid: self(),
      custom_state: payload
    }
    DynamicSupervisor.start_child( SubserverSupervisor, {Subserver, init_state})
  end
end
