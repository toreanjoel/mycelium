defmodule Mycelium.Servers.Helpers do
  @moduledoc """
    Helper functions in order to interact with servers and their rooms/channels.
  """

  @doc """
    Get all the relevant rooms/channels the created server has available.
  """
  def get_channels(server_id) do
    {_, p_name} = internal_server_name(server_id(server_id))
    GenServer.call(p_name, :get_channels)
  end

  @doc """
    Update the state of the server room/channel by passing the data payload.
    The sub server is responsible for updating in the correct fasion given the state type.
  """
  def update_channel_state(server_id, channel, data) do
    {_, p_name} = internal_server_name(server_id(server_id))
    GenServer.call(p_name, {:update_channel, channel, data})
  end

  @doc """
    Get the room/channel details, this will include meta data and the current state.
    We also get information on the the room metadata and state at the current time or the
    struct representation of the state.
  """
  def get_channel(server_id, channel) do
    {_, p_name} = internal_server_name(server_id(server_id))
    GenServer.call(p_name, {:get_channel, channel})
  end

  @doc """
    Create a room/channel of a given type for current server.
    Note: shared server channels have a default state that needs to be set on init or defaits to %{}
  """
  def create_channel(server_id, room, type) when type in [:accumulative_state, :collaborative_state] do
    {_, p_name} = internal_server_name(server_id(server_id))
    GenServer.call(p_name, {:create_channel, room, type})
  end

  def create_channel(server_id, room, type, payload \\ %{}) when type === :shared do
    {_, p_name} = internal_server_name(server_id(server_id))
    GenServer.call(p_name, {:create_channel, room, type, payload})
  end

  # Get the server ID
  defp server_id(id) do
    servers = GenServer.call(Mycelium.Servers.SubserverManager, :get_servers)
    Map.get(servers, id, false)
  end

  # Servers are made with dynamic supercisors, their name is genearted with their ID
  defp internal_server_name(pid) do
    Process.info(pid) |> List.first()
  end
end
