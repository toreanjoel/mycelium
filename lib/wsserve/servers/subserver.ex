defmodule Wsserve.Servers.Subserver do
  @moduledoc """
    This is the server for each of the socker processes that will manage state.
    This will manage room states (later agents per room) but general channel data
    clients interact against.

    Server manager is repsonsibile for asking a dynamic supervisor to init with relevant config
  """
  use GenServer, restart: :temporary
  require Logger

  def start_link(args \\ %{}) do
    uuid = UUID.uuid4()

    GenServer.start_link(
      __MODULE__,
      Map.merge(args, %{
        id: uuid
      }),
      name: String.to_atom(Atom.to_string(__MODULE__) <> ":" <> uuid)
    )
  end

  def init(args) do
    config = %Wsserve.Servers.Subserver.Config{
      pid: self(),
      manager_pid: args.manager_pid,
      id: Map.get(args, :id, UUID.uuid4())
    }

    # we set the deafault state of allowing a lobby for all servers
    base_state = %{
      config: config,
      channel_states: %{
        "lobby" => Wsserve.Servers.Subserver.Structs.generate_type()
      }
    }

    state =
      case init_state = args.custom_state do
        nil ->
          base_state

        _ ->
          Map.merge(base_state, Map.delete(init_state, :config))
      end

    # tell parent that we are ready with config details
    send(args.manager_pid, {:server_config, state.config})
    {:ok, state}
  end

  # Get the current config details stored
  def handle_call(:get_config, _from, state) do
    if data = Map.get(state, :config, false) do
      {:reply, {:ok, data}, state}
    else
      {:reply, {:error, "No config found. Make sure it exists"}, state}
    end
  end

  # Returns all the room states that exist currently
  def handle_call(:get_channels, _from, state) do
    {:reply, Map.keys(state.channel_states), state}
  end

  # Get the state by the channel name currently stored in the server
  def handle_call({:get_channel, channel}, _from, state) do
    if data = Map.get(state.channel_states, channel, false) do
      {:reply, {:ok, data}, state}
    else
      {:reply, {:error, "No channel found, create or make sure it exists."}, state}
    end
  end

  # TODO: The updating of the config wont be needed for now
  # Update the config property. Will replace what is currently there if it already exists
  # def handle_call({:update_config, key, value}, _from, state) do
  #   updated_config = Map.put(state.config, key, value)
  #   updated_state = Map.put(state, :config, updated_config)
  #   {:reply, updated_state, updated_state}
  # end

  # Sync: Update the state of the specific channel - will merge to the data currenly existing in memory
  def handle_call({:update_channel, channel, data}, _from, state) do
    curr_channel = Map.get(state.channel_states, channel, false)
    if curr_channel do
      type = curr_channel.type
      updated_state = update_channel(channel, data, state, type)
      {:reply, {:ok, updated_state}, updated_state}
    else
      Logger.error("Unable to find channel to update")
      {:reply, {:ok, state}, state}
    end
  end

  # create a channel by type either collab or accumulative
  def handle_call({:create_channel, channel_name, type}, _from, state) do
    channel =
      Map.put(
        state.channel_states,
        channel_name,
        Wsserve.Servers.Subserver.Structs.generate_type(type)
      )

    new_state = Map.put(state, :channel_states, channel)
    {:reply, {:ok, "Channel #{channel_name} created"}, new_state}
  end

  # TODO: Think about if this is reelant
  # Async: Update the state of the specific channel - will merge to the data currenly existing in memory
  # def handle_cast({:update_channel, channel, data}, state) do
  #   updated_state = update_channel(channel, data, state)
  #   {:noreply, updated_state}
  # end

  # here we listen for the requests to send configs to process to manage
  def handle_info({:request_config, caller_pid}, state) do
    send(caller_pid, {:server_config, state.config})
    {:noreply, state}
  end

  # Here we update channel data to the state
  def update_channel(channel, data, %{channel_states: channel_states} = state, type)
    when type in [:accumulative, :collaborative] do
  curr_channel = Map.get(channel_states, channel, %{})

  updated_details =
    case type do
      :accumulative ->
        payload = Map.new() |> Map.put(DateTime.utc_now() |> DateTime.to_unix(), data)
        Map.merge(curr_channel.state, payload)

      :collaborative ->
        # Assuming data is a map with user ID as key and payload as value
        payload = Map.new() |> Map.put(data.user.id, data)
        Map.merge(curr_channel.state, payload)

      _ ->
        Logger.error("Unknown channel type: #{inspect(type)}")
        curr_channel.state
    end

  updated_channel_states = Map.put(channel_states, channel, %{curr_channel | state: updated_details})
  Map.put(state, :channel_states, updated_channel_states)
end

end
