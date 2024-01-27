defmodule MyceliumWeb.Events do
  @moduledoc """
    The events that we use for the channels, this is so its easy to change but mainly
    for incoming and outgoing broadcasting events.
  """

  @evnts_in %{
    server_req: "push",
    get_rooms: "get_rooms",
  }

  @evnts_out %{
    presence_evnt: "presence",
    state_evnt: "state",
    server_resp: "msg",
    rooms: "rooms"
  }

  @doc """
    Return the event assigned to incoming event data
  """
  def server_req_evnt(), do: Map.get(@evnts_in, :server_req)

  @doc """
    Return the event assigned to outgoing data
  """
  def server_resp_evnt(), do: Map.get(@evnts_in, :server_resp)

  @doc """
    Get the server and available rooms event
  """
  def get_rooms_evnt(), do: Map.get(@evnts_in, :get_rooms)

  @doc """
    Return the event assigned to presence
  """
  def presence_evnt(), do: Map.get(@evnts_out, :presence_evnt)

  @doc """
    Return the event assigned to state or last known state
  """
  def state_evnt(), do: Map.get(@evnts_out, :state_evnt)

  @doc """
    Get the server and available rooms event
  """
  def rooms_evnt(), do: Map.get(@evnts_out, :rooms)
end
