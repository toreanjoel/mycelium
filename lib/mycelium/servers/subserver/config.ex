defmodule Mycelium.Servers.Subserver.Config do
  @moduledoc """
    The struct that describes the general confif of a server
  """
  @enforce_keys [:pid, :id, :manager_pid]
  defstruct [:pid, :id, manager_pid: nil]
end
