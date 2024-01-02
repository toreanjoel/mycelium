defmodule WsserveWeb.RoomChannel do
  use WsserveWeb, :channel
  alias WsserveWeb.Presence
  # use Phoenix.Channel

  # we list the events we want to have the interception work for
  # we can do work before sending
  intercept ["shout"]

  @impl true
  def join(room, payload, socket) do
    # user joined the channel
    send(self(), :user_joined)
    # This is the response after joining, we send a response
    {:ok, %{"message" => "Welcome to room:" <> room}, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
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
  @spec handle_out(<<_::40>>, any(), Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_out("shout", payload, socket) do
    push(socket, "shout", payload)
    {:noreply, socket}
  end

  # Listener to user joined event
  @impl true
  def handle_info(:user_joined, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user.id, %{
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_list", Presence.list(socket))
    {:noreply, socket}
  end

  # If we want to send to any channel between modules and app we use
  # Specify the relevant channel and it will be sent to all connected to that channel
  # WsserveWeb.Endpoint.broadcast!("room:lobby", "new_msg", %{uid: "123", body: "body"})
end
