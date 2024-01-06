defmodule WsserveWeb.RoomChannel do
  use WsserveWeb, :channel
  alias WsserveWeb.Presence
  # use Phoenix.Channel

  # we list the events we want to have the interception work for
  # we can do work before sending
  intercept(["shout"])

  @impl true
  def join("lobby", _payload, socket) do
    # IO.inspect(channel)
    # user joined the channel
    send(self(), :user_joined_lobby)
    # This is the response after joining, we send a response
    {:ok, %{message: "Welcome to room lobby"}, socket}
  end

  # no access to the channel for access
  def join(room, _payload, socket) do
    # This is the response after joining, we send a response
    # IO.inspect("room")
    # IO.inspect(room)
    {status, _} = get_channel(socket.assigns.server_id, room)

    case status do
      :error ->
        {:error,
         %{
           message:
             "Room doesn't exist. Request room data from 'room:lobby' in order to get options available"
         }}

      _ ->
        send(self(), {:user_joined_room, room})
        {:ok, socket}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("push", payload \\ %{}, socket) do
    server_id = socket.assigns.server_id
    channel = socket.topic
    # basic data structure for now
    event_data = %{
      user: socket.assigns.user.id,
      payload: payload
    }

    data = Map.new() |> Map.put(DateTime.utc_now() |> DateTime.to_unix, event_data)

    update_channel_state(server_id, channel, data)

    {_, data} = get_channel(server_id, channel)
    broadcast_from!(socket, "msg", %{ data: data})

    {:reply, {:ok, event_data}, socket}
  end

  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (sub_serve:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    # we send to all excluding the current user
    broadcast_from!(socket, "shout", payload)
    {:noreply, socket}
  end

  # Disconnect the user from the current topic
  @impl true
  def handle_in("disconnect", _payload, socket) do
    # pushing will allow sending a message not related to this code block
    push(socket, "disconnecting", %{
      "data" => "You will me removed and are require to restart to reconnect"
    })

    {:stop, :shutdown, socket}
  end

  # catch before the message get sent out
  @impl true
  def handle_out("shout", payload, socket) do
    push(socket, "shout", payload)
    {:noreply, socket}
  end

  # Listener to user joined event
  @impl true
  def handle_info(:user_joined_lobby, socket) do
    # push the presence for the channel
    push_channel_presence(socket)

    # send the room options available to the current user
    push(socket, "available_rooms", %{data: get_channels(socket.assigns.server_id)})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:user_joined_room, room}, socket) do
    # push the presence for the channel
    push_channel_presence(socket)

    {_status, data} = get_channel(socket.assigns.server_id, room)
    push(socket, "room_state", %{data: data})

    {:noreply, socket}
  end

  # Helper functions in order to interact with the current server
  defp get_channels(server_id) do
    p_server = get_server_id(server_id)
    {_, p_name} = get_server_name(p_server)
    GenServer.call(p_name, :get_channels)
  end

  # update the state
  defp update_channel_state(server_id, channel, data) do
    p_server = get_server_id(server_id)
    {_, p_name} = get_server_name(p_server)
    GenServer.call(p_name, {:update_channel, channel, data})
  end

  # get details of a specific channel
  defp get_channel(server_id, channel) do
    p_server = get_server_id(server_id)
    {_, p_name} = get_server_name(p_server)
    GenServer.call(p_name, {:get_channel, channel})
  end

  # init a new room on the current server
  defp create_channel(server_id, room) do
    p_server = get_server_id(server_id)
    {_, p_name} = get_server_name(p_server)
    GenServer.call(p_name, {:create_channel, room})
  end

  # get the server id
  defp get_server_id(server_id) do
    servers = GenServer.call(Wsserve.Servers.SubserverManager, :get_servers)
    Map.get(servers, server_id, false)
  end

  # get the dynamic server room name - atom server name
  defp get_server_name(p_server) do
    Process.info(p_server) |> List.first()
  end

  # send the presence for the connected channel
  defp push_channel_presence(socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user.id, %{
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_list", Presence.list(socket))
  end

  # If we want to send to any channel between modules and app we use
  # Specify the relevant channel and it will be sent to all connected to that channel
  # WsserveWeb.Endpoint.broadcast!("room:lobby", "new_msg", %{uid: "123", body: "body"})
end
