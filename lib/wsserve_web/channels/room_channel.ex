defmodule WsserveWeb.RoomChannel do
  use WsserveWeb, :channel
  alias WsserveWeb.Presence
  alias WsserveWeb.Channels.Helpers, as: ChannelHelpers

  # we list the events we want to have the interception work for
  # we can do work before sending
  intercept(["shout"])

  # no access to the channel for access
  def join(room, _payload, socket) do
    {status, _} = ChannelHelpers.get_channel(socket.assigns.server_id, room)
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

  @impl true
  def handle_in("push", payload \\ %{}, socket) do
    server_id = socket.assigns.server_id
    channel = socket.topic

    event_data = %WsserveWeb.Channels.Structs.PushPayload{
      user: socket.assigns.user,
      payload: payload
    }

    ChannelHelpers.update_channel_state(server_id, channel, event_data)
    {_, data} = ChannelHelpers.get_channel(server_id, channel)
    broadcast(socket, "msg", %{ data: data})

    {:reply, {:ok, event_data}, socket}
  end

  @impl true
  def handle_info({:user_joined_room, room}, socket) do
    # push the presence for the channel
    push_presence(socket)
    {_status, data} = ChannelHelpers.get_channel(socket.assigns.server_id, room)
    push(socket, "state", %{data: data})

    {:noreply, socket}
  end

  # send the presence for the connected channel
  defp push_presence(socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user.id, %{
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_list", Presence.list(socket))
  end
end
