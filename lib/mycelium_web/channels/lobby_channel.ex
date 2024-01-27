defmodule MyceliumWeb.LobbyChannel do
  @moduledoc """
    Lobby channel module that manages the conection to the lobby channel that all servers have access to.
    Main funcitonality is to server as a gateway for channel connections to get data on serverss
  """
  use MyceliumWeb, :channel
  alias MyceliumWeb.Presence
  alias Mycelium.Servers.Helpers, as: ServerHelpers

  @impl true
  @doc """
    Join lobbt channel and on success start broadcasing presence updates
  """
  def join("lobby", _payload, socket) do
    send(self(), :user_joined_lobby)
    {:ok, %{}, socket}
  end

  @impl true
  @doc """
    Event listener for clients that call the function to get details on available rooms on the connected server.
  """
  def handle_in("get_rooms", _, socket) do
    push_rooms(socket)
    {:noreply, socket}
  end

  @doc """
    Listener to init the room and broadcast room/presece data from helper function calls
  """
  @impl true
  def handle_info(:user_joined_lobby, socket) do
    push_presence(socket)
    push_rooms(socket)
    {:noreply, socket}
  end

  # Presence helper that will assign and track connected socket.
  # Also broadcast the updated presence list to connected users on the socket channel.
  defp push_presence(socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user.id, %{
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence", Presence.list(socket))
  end

  # Get and send the room details currently avalable on the connected server for the current channel
  defp push_rooms(socket) do
    push(socket, "rooms", %{data: ServerHelpers.get_channels(socket.assigns.server_id)})
    {:noreply, socket}
  end
end
