defmodule WsserveWeb.Channels.Structs do
  @moduledoc """
    The structs around payloads passing between channels as data from clients
  """

  defmodule PushPayload do
    @moduledoc """
      The payload the client sends as data to the channels
    """
    @enforce_keys [:user, :payload]
    defstruct [:user, :payload]
  end
end
