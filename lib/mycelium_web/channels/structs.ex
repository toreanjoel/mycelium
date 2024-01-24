defmodule MyceliumWeb.Channels.Structs do
  @moduledoc """
    The structs around payloads passing between channels as data from clients
  """

  defmodule PushPayload do
    @moduledoc """
      The payload the client sends as data to the channels
    """
    @derive {Jason.Encoder, only: [:user, :payload]}
    @enforce_keys [:user, :payload]
    defstruct [:user, :payload]
  end
end
