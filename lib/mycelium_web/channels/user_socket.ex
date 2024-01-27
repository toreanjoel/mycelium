defmodule MyceliumWeb.UserSocket do
  @moduledoc """
    The user socket module than handles the socket connect, server connection.
    Seting the server to the user connection in order to join channels with in the
    context of the server.
  """
  require Logger
  use Phoenix.Socket

  channel "lobby", MyceliumWeb.LobbyChannel
  channel "*", MyceliumWeb.RoomChannel

  @doc """
    Socket connection with relevant params to a specific server.
  """
  @impl true
  def connect(%{"id" => server_id} = payload, socket, _connect_info) do
    servers = GenServer.call(Mycelium.Servers.SubserverManager, :get_servers)
    if Map.get(servers, server_id, false) do
      # Validity for how long we want to keep the user connected - currently 2 weeks
      # case Phoenix.Token.verify(socket, @salt, token, max_age: 1_209_600) do
      #   {:ok, user} ->
      #     # we add the user id to the socket from the token
      #     socket = assign(socket, :user, user) |> assign(:server_id, id)
      #     {:ok, socket}
      #   {:error, _reason} ->
      #     :error # we just stop the connection going forward
      #   end

      user_data = %{
        id: Map.get(payload, "userId", UUID.uuid4())
      }

      {:ok, assign(socket, :server_id, server_id) |> assign(:user, user_data)}
      else
        :error # we just stop the connection going forward
    end
  end


  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.MyceliumWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
