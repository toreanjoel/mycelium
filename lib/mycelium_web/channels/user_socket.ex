defmodule MyceliumWeb.UserSocket do
  require Logger
  use Phoenix.Socket

  @salt "user_auth_salt"

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels
  # Uncomment the following line to define a "room:*" topic
  # pointing to the `MyceliumWeb.RoomChannel`:
  #
  # channel "room:*", MyceliumWeb.RoomChannel
  #
  # To create a channel file, use the mix task:
  #
  #     mix phx.gen.channel Room
  #
  # See the [`Channels guide`](https://hexdocs.pm/phoenix/channels.html)
  # for further details.
  channel "lobby", MyceliumWeb.LobbyChannel
  channel "*", MyceliumWeb.RoomChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error` or `{:error, term}`. To control the
  # response the client receives in that case, [define an error handler in the
  # websocket
  # configuration](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-websocket-configuration).
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
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
