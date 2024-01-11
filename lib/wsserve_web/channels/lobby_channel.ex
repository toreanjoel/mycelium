defmodule WsserveWeb.LobbyChannel do
  use WsserveWeb, :channel
  alias WsserveWeb.Presence
  alias WsserveWeb.Channels.Helpers, as: ChannelHelpers

  @impl true
  def join("lobby", _payload, socket) do
    send(self(), :user_joined_lobby)
    {:ok, %{}, socket}
  end

  @impl true
  def handle_in("get_rooms", _, socket) do
    push_rooms(socket)
    {:noreply, socket}
  end

  # Listener to user joined event
  @impl true
  def handle_info(:user_joined_lobby, socket) do
    push_presence(socket)
    push_rooms(socket)
    {:noreply, socket}
  end

  # send the presence for the connected channel
  def push_presence(socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user.id, %{
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_list", Presence.list(socket))
  end

  # send rooms to the requesting user
  defp push_rooms(socket) do
    push(socket, "available_rooms", %{data: ChannelHelpers.get_channels(socket.assigns.server_id)})
    {:noreply, socket}
  end
end
