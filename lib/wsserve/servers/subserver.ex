defmodule Wsserve.Servers.Subserver do
  @moduledoc """
    This is the server for each of the socker processes that will manage state.
    This will manage room states (later agents per room) but general channel data
    clients interact against.

    Server manager is repsonsibile for asking a dynamic supervisor to init with relevant config
  """
  use GenServer
  require Logger

  def start_link(args) do
    identifier = Atom.to_string(__MODULE__) <> ":" <> args.id
    GenServer.start_link(__MODULE__, args, name: String.to_atom(identifier) )
  end

  # Init the server with relevant states
  def init(args) do
    init_state = %{
      config: %{
        pid: self(),
        id: Map.get(args, :id, UUID.uuid4())
      },
      channel_states: %{}
    }
    # tell parent that we are ready with config details
    send(args.manager_pid, {:server_config, init_state.config})
    {:ok, init_state}
  end

  # Get the current config details stored
  def handle_call(:get_config, _from, state) do
    {:reply, Map.get(state, :config, "No config found. Make sure it exists"), state}
  end

  # Returns all the room states that exist currently
  def handle_call(:all_channels, _from, state) do
    {:reply, Map.keys(state.channel_states), state}
  end

  # Get the state by the channel name currently stored in the server
  def handle_call({:get_channel, channel}, _from, state) do
    {:reply, Map.get(state.channel_states, channel, "No channel found, create or make sure it exists."), state}
  end

  # Update the config property. Will replace what is currently there if it already exists
  def handle_call({:update_config, key, value}, _from, state) do
    updated_config = Map.put(state.config, key, value)
    updated_state = Map.put(state, :config, updated_config)
    {:reply, updated_state, updated_state}
  end

  # Sync: Update the state of the specific channel - will merge to the data currenly existing in memory
  def handle_call({:update_channel, channel, data}, _from, state) do
    updated_state = update_channel_data(channel, data, state)
    {:reply, updated_state, updated_state}
  end

  # TODO: Think about if this is reelant
  # Async: Update the state of the specific channel - will merge to the data currenly existing in memory
  # def handle_cast({:update_channel, channel, data}, state) do
  #   updated_state = update_channel_data(channel, data, state)
  #   {:noreply, updated_state}
  # end

  # here we listen for the requests to send configs to process to manage
  def handle_info({:request_config, caller_pid}, state) do
    send(caller_pid, {:server_config, state.config})
    {:noreply, state}
  end

  # Here we update channel data to the state
  defp update_channel_data(channel, data, state) do
    curr_channel = Map.get(state.channel_states, channel)
    updated_details = case curr_channel do
      nil -> Map.new() |> Map.put_new(channel, data)
      _ -> Map.merge(curr_channel, data)
    end

    # replace the old channel
    updated_channel = Map.put(state.channel_states, channel, updated_details)
    Map.put(state, :channel_states, updated_channel)
  end

  # TODO: setup the job process to check activity and batch update current state
end
