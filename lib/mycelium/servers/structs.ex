defmodule Mycelium.Servers.Structs do
  @moduledoc """
    The general server structs that describe data and their definitions
  """
  defmodule ServerManagerInit do
    @moduledoc """
      The server manage init state used to describe the registry that manages the running subservers
    """
    @derive {Jason.Encoder, only: [:servers]}
    @enforce_keys [:servers]
    defstruct [servers: %{}]
  end

  defmodule SubServerInit do
    @moduledoc """
      The struct that describes the data when creating or requesting to create a instance
    """
    @derive {Jason.Encoder, only: [:manager_pid, :custom_state]}
    @enforce_keys [:manager_pid, :custom_state]
    defstruct [:manager_pid, :custom_state]
  end

  defmodule Channel do
    @moduledoc """
      The channel struct used to represent state and type data of how state will be accumulated for a chanenel
    """
    # TODO: This needs to be more strict, especially for types
    @derive {Jason.Encoder, only: [:type, :state]}
    defstruct [type: :shared_state, state: %{}]
  end

  defmodule Config do
    @moduledoc """
      Config or general metadata of a server that keeps track of its name and pids referencing it
    """
    @enforce_keys [:pid, :id, :manager_pid]
    defstruct [:pid, :id, manager_pid: nil]
  end

  defmodule EventPayload do
    @moduledoc """
      The structure of what you use to send data to server channels
    """
    @derive {Jason.Encoder, only: [:user, :payload]}
    @enforce_keys [:user, :payload]
    defstruct [:user, :payload]
  end
end
