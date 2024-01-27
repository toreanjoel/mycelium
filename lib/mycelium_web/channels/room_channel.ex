defmodule MyceliumWeb.RoomChannel do
  @moduledoc """
    The general room connection outside of the lobby channel. This is for all other channels.
    The system will only allow based on the servers and the relevancy of them existing.
  """
  use MyceliumWeb, :channel
  alias MyceliumWeb.Presence
  alias Mycelium.Servers.Helpers, as: ServerHelpers
  alias Mycelium.Servers.Structs.EventPayload

  @impl true
  @doc """
    Join attempt to passed channel. Checking the server for rooms to allow only channels that exist
  """
  def join(room, _payload, socket) do
    {status, _} = ServerHelpers.get_channel(socket.assigns.server_id, room)
    server_join(status, socket, room)
  end

  @impl true
  @doc """
    The push event that all rooms have in order of the client to be able to send data to connected channel.
  """
  def handle_in("push", payload \\ %{}, %{assigns: assigns, topic: topic} = socket) do
    server_id = assigns.server_id

    # This is Genserver call, we dont use result but good to note.
    _resp = ServerHelpers.update_channel_state(
        server_id,
        topic,
        %EventPayload{user: assigns.user, payload: payload}
      )
    {_, data} = ServerHelpers.get_channel(server_id, topic)

    # broadcast to all including the sender? consider using the broadcast_from and caller ref the result
    broadcast(socket, "msg", %{ data: data})
    {:reply, {:ok, data}, socket}
  end

  @impl true
  @doc """
    Listener to init the room and broadcast room/presece data from helper function calls
  """
  def handle_info({:user_joined_room, room}, socket) do
    # push the presence for the channel
    push_presence(socket)

    {_status, data} = ServerHelpers.get_channel(socket.assigns.server_id, room)
    push(socket, "state", %{data: data})

    {:noreply, socket}
  end

  # send the presence for the connected channel
  defp push_presence(socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user.id, %{
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence", Presence.list(socket))
  end

  @doc """
    We attempt to join the room if exists based on server and show relevant response oside effect
  """
  def server_join(status, _socket, _) when status === :error do
    {
      :error,
      %{
        message:
          "Room doesn't exist. Request room data from 'room:lobby' in order to get options available"
      }
    }
  end

  def server_join(_status, socket, room) do
    send(self(), {:user_joined_room, room})
    {:ok, socket}
  end
end
