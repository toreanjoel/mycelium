defmodule Wsserve.Servers.Subserver.Structs do
  @moduledoc """
    The different types of servers that will have deatils at a channel level.
    This sets the data around how the system will be updating the room
  """
  # TODO: This needs to be more strict, especially for types
  @derive {Jason.Encoder, only: [:type, :state]}
  @enforce_keys [:type, :state]
  defstruct [type: :shared_state, state: %{}]
end
