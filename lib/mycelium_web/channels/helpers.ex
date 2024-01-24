defmodule MyceliumWeb.Channels.Helpers do
  @moduledoc """
    This is the helper functions used for channels interactive with the server mangers
  """

  # Helper functions in order to interact with the current server
  def get_channels(server_id) do
    p_server = get_server_id(server_id)
    {_, p_name} = get_server_name(p_server)
    GenServer.call(p_name, :get_channels)
  end

  # update the state
  def update_channel_state(server_id, channel, data) do
    p_server = get_server_id(server_id)
    {_, p_name} = get_server_name(p_server)
    GenServer.call(p_name, {:update_channel, channel, data})
  end

  # get details of a specific channel
  def get_channel(server_id, channel) do
    p_server = get_server_id(server_id)
    {_, p_name} = get_server_name(p_server)
    GenServer.call(p_name, {:get_channel, channel})
  end

  # init a new room on the current server
  def create_channel(server_id, room, type) do
    p_server = get_server_id(server_id)
    {_, p_name} = get_server_name(p_server)
    GenServer.call(p_name, {:create_channel, room, type})
  end

  # get the server id
  def get_server_id(server_id) do
    servers = GenServer.call(Mycelium.Servers.SubserverManager, :get_servers)
    Map.get(servers, server_id, false)
  end

  # get the dynamic server room name - atom server name
  def get_server_name(p_server) do
    Process.info(p_server) |> List.first()
  end
end
