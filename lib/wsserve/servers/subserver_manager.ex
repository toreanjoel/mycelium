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
    # TODO: Add a way to check if the processes in memory are active with process info, cleanup otherwise
    {:ok,
     %{
       servers: %{}
       # TODO: Add more items here that we wish the manager to track later
     }}
  end

  # Get server state curr in memory
  # TODO: this needs to be grouped by user id or the subserver itself needs to be dynamic per user
  def handle_call(:get_servers, _from, state) do
    {:reply, Map.get(state, :servers), state}
  end

  # Create sub server
  def handle_call(:create_server, _from, state) do
    {status, _} = request_create_server()

    case status do
      :ok ->
        {:reply, state, state}

      _ ->
        Logger.error("There was a problem creating the server")
        {:reply, "There was a problem creating the server", state}
    end
  end

  # delete a sub server
  def handle_call({:delete_server, server_id}, _from, state) do
    # we get the process by id
    pid = Map.get(state.servers, server_id, false)

    if pid do
      case DynamicSupervisor.terminate_child(SubserverSupervisor, pid) do
        :ok ->
          updated_servers_state = remove_from_registry(state, server_id)
          {:reply, updated_servers_state, updated_servers_state}

        _ ->
          Logger.error(
            "Unable to delete process. There was a probllem removing subserver isntance"
          )

          {:reply, state, state}
      end
    else
      Logger.error("Unable to delete process, not found in registry")
      {:reply, state, state}
    end
  end

  # remove reference to process and pid
  def handle_info({:server_config, %{id: server_id, pid: server_pid}}, state) do
    # we start monitoring the process for other messages
    # we get a ref that when things crash we need to use to cleanup manager state
    Process.monitor(server_pid)

    # add the process inder the server
    added_server = Map.put(state.servers, server_id, server_pid)
    updated_state = Map.put(state, :servers, added_server)
    {:noreply, updated_state}
  end

  # Subserver was shut down
  def handle_info({:DOWN, _ref, _, _, reason}, state) when reason === :shutdown do
    Logger.info("Subserver was shut down")
    # Here we should remove but we need to store process refs in order to track pid when using callback monitoring
    {:noreply, state}
  end

  # TODO: account for the missing
  # {:DOWN, #Reference<0.794012290.1310721.23505>, :process, #PID<0.613.0>, {{:badkey, :id, "torean"}, [{Wsserve.Servers.Subserver, :channel_state_update, 4, [file: 'lib/wsserve/servers/subserver.ex', line: 133]}, {Wsserve.Servers.Subserver, :handle_call, 3, [file: 'lib/wsserve/servers/subserver.ex', line: 93]}, {:gen_server, :try_handle_call, 4, [file: 'gen_server.erl', line: 1113]}, {:gen_server, :handle_msg, 6, [file: 'gen_server.erl', line: 1142]}, {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 241]}]}}
  # State: %{servers: %{"5428744d-b465-4098-aa25-634c0e31d804" => #PID<0.613.0>}}

  # Subserver dies or crashes for some reason
  def handle_info({:DOWN, _ref, _, _, data}, state) do
    case data do
      {_, [{_, _, [_, _, prev_process_state], _}, _, _, _]} ->
        # NOTE: here we send the entire prev state so it will include configs etc
        # This might not be need for the users
        {status, _} = request_create_server(prev_process_state)

        case status do
          :ok ->
            Logger.info("Successfully revived crashed server data with last known data")
            # Delete the ref in the state of the crashed process from the manager
            {:noreply, remove_from_registry(state, Kernel.get_in(prev_process_state, [:config, :id]))}

          _ ->
            Logger.error("There was a problem creating the server (recreate from falling)")
            {:noreply, state}
        end
      _ ->
        # TODO: move this to a separate function
        Logger.error("Error, process DOWN error")
        {:noreply, state}
    end
  end

  # unhanled process message here
  def handle_info(event, state) do
    Logger.info("Unhandled process message")
    Logger.info("Event: \n #{inspect(event)}")
    {:noreply, state}
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

    DynamicSupervisor.start_child(SubserverSupervisor, {Subserver, init_state})
  end

  # Takes the state and returns a new state to be used removing servers from memory
  defp remove_from_registry(state, server_id) when is_map(state) and is_binary(server_id) do
    updated_servers = Map.get(state, :servers) |> Map.delete(server_id)
    Map.put(state, :servers, updated_servers)
  end
end
