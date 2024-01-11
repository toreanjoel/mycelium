defmodule Wsserve.Servers.Subserver.Structs do
  @moduledoc """
    The different types of servers that will have deatils at a channel level.
    This sets the data around how the system will be updating the room
  """
  defstruct [type: :default, state: %{}]

  @doc """
    Return an instnace of the relevant type to init with
  """
  def generate_type(type \\ :none) do
    case type do
      :accumulative -> %Wsserve.Servers.Subserver.Structs{
        type: :accumulative,
        state: %{}
      }
      :collaborative -> %Wsserve.Servers.Subserver.Structs{
        type: :collaborative,
        state: %{}
      }
      _ -> %Wsserve.Servers.Subserver.Structs{
        type: :default,
        state: %{}
      }
    end
  end

end
