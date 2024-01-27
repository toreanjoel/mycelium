defmodule Mycelium.Servers.Subserver do
  @moduledoc """
    This is the server for each of the socker processes that will manage state.
    This will manage room states (later agents per room) but general channel data
    clients interact against.

    Server manager is repsonsibile for asking a dynamic supervisor to init with relevant config
  """
  use GenServer, restart: :temporary
  alias Mycelium.Servers.Structs
  require Logger

  @doc false
  def start_link(args \\ %{}) do
    id =
      args
      |> Map.get(:custom_state, %{})
      |> Map.get(:config, %{})
      |> Map.get(:id, UUID.uuid4())

    GenServer.start_link(
      __MODULE__,
      Map.merge(args, %{id: id}),
      name: String.to_atom(Atom.to_string(__MODULE__) <> ":" <> id)
    )
  end

  @doc false
  def init(%{manager_pid: manager_pid, id: id, custom_state: init_state}) do
    state =
      if is_nil(init_state) do
        init_base_state(manager_pid, id)
      else
        # We only copy the channel data if there was a config before - delete the config
        Map.merge(init_base_state(manager_pid, id), Map.delete(init_state, :config))
      end

    # tell parent that we are ready with config details
    send(manager_pid, {:server_config, state.config})
    {:ok, state}
  end

  @doc """
    Get the server config details
  """
  def handle_call(:get_config, _from, state) when is_nil(state.config) do
    {:reply, {:error, "No config found. Make sure it exists."}, state}
  end

  def handle_call(:get_config, _from, %{config: config} = state) do
    {:reply, {:ok, config}, state}
  end

  @doc """
    The the server channels that currently exist
  """
  def handle_call(:get_channels, _from, state) do
    {:reply, Map.keys(state.channel_states), state}
  end

  @doc """
    Get the state by the channel name currently stored in the server
  """
  def handle_call({:get_channel, channel}, _from, state) do
    get_channel(Map.get(state.channel_states, channel), state)
  end

  @doc """
    Update the state of the specific channel - will merge to the data currenly existing in memory
  """
  def handle_call({:update_channel, channel, data}, _from, state) do
    update_channel(
      Map.get(state.channel_states, channel), channel, data, state);
  end

  @doc """
    Global room or channel state that will be initalized with properties
  """
  def handle_call({:create_channel, name, type, payload}, _from, %{channel_states: channel_states} = state) do
    create_channel(channel_states, name, payload, type, state)
  end

  def handle_call({:create_channel, name, type}, _from, %{channel_states: channel_states} = state) do
    create_channel(channel_states, name, nil, type, state)
  end

  # here we listen for the requests to send configs to process to manage
  def handle_info({:request_config, caller_pid}, state) do
    send(caller_pid, {:server_config, state.config})
    {:noreply, state}
  end

  @doc """
    The update specific to the state itself for the relevant type - accumulative
  """
  defp channel_state_update(channel, data, %{channel_states: channel_states} = state, type) when type === :accumulative_state do
    curr_channel = Map.get(channel_states, channel, %{})
    payload = Map.new() |> Map.put(DateTime.utc_now() |> DateTime.to_unix(), data)
    updated_details = Map.merge(curr_channel.state, payload)

    updated_channel_states =
      Map.put(channel_states, channel, %{curr_channel | state: updated_details})

    Map.put(state, :channel_states, updated_channel_states)
  end

  @doc """
    The update specific to the state itself for the relevant type - collaborative
  """
  defp channel_state_update(channel, data, %{channel_states: channel_states} = state, type) when type === :collaborative_state do
    curr_channel = Map.get(channel_states, channel, %{})
    # Assuming data is a map with user ID as key and payload as value
    payload = Map.new() |> Map.put(data.user.id, data)
    updated_details = Map.merge(curr_channel.state, payload)

    updated_channel_states =
      Map.put(channel_states, channel, %{curr_channel | state: updated_details})

    Map.put(state, :channel_states, updated_channel_states)
  end

  @doc """
    The update specific to the state itself for the relevant type - shared state
  """
  defp channel_state_update(channel, data, %{channel_states: channel_states} = state, type) when type === :shared_state do
    curr_channel = Map.get(channel_states, channel, %{})
    room_state = curr_channel.state
    # Here we take the passed data and try add
    updated_init =
      Enum.reduce(Map.keys(data.payload), room_state, fn curr_data_key, curr_room_state ->
        if Map.has_key?(curr_room_state, curr_data_key) do
          Map.put(curr_room_state, curr_data_key, Map.get(data.payload, curr_data_key))
        else
          curr_room_state
        end
      end)

    updated_details = Map.merge(room_state, updated_init)

    updated_channel_states =
      Map.put(channel_states, channel, %{curr_channel | state: updated_details})

    Map.put(state, :channel_states, updated_channel_states)
  end

  # Base state init
  defp init_base_state(manager_pid, id) do
    %{
      config: %Structs.Config{
        pid: self(),
        manager_pid: manager_pid,
        id: id
      },
      channel_states: %{
        "lobby" => %Structs.Channel{type: :default, state: %{}}
      }
    }
  end

  # Here we check if the channel is nil, default fallback otherwise
  defp update_channel(data, _, _, state) when is_nil(data) do
    Logger.error("Unable to find channel to update")
    {:reply, {:ok, state}, state}
  end

  # Update a channel and the data for that channel if it exists
  defp update_channel(%{type: type}, channel, data, state) do
    updated_state = channel_state_update(channel, data, state, type)
    {:reply, {:ok, updated_state}, updated_state}
  end

  # Check there is data in the state, fallback error
  defp get_channel(data, state) when is_nil(data)do
    {:reply, {:error, "No channel found, create or make sure it exists."}, state}
  end

  # Return the data if exists - it will be passed if it exists
  defp get_channel(data, state) do
    {:reply, {:ok, data}, state}
  end

  # Check there is data in the state, fallback error
  defp create_channel(channel_states, name, payload, type, state) when type == :shared_state do
    new_state = Map.put(state, :channel_states,  Map.put(channel_states, name, %Structs.Channel{ state: payload}))
    {:reply, {:ok, "Channel #{name} created with type #{type}"}, new_state}
  end

  # Check there is data in the state, fallback error
  defp create_channel(channel_states, name, _, type, state) when type in [:collaborative_state, :accumulative_state] do
    channel =
      Map.put(
        channel_states,
        name
          |> String.trim
          |> String.downcase
          |> String.replace(" ", "_"),
        %Structs.Channel{type: type}
      )

    updated_state = Map.put(state, :channel_states, channel)
    {:reply, {:ok, "Channel #{name} created with type #{type}"}, updated_state}
  end
end
