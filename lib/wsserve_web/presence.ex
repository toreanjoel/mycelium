defmodule WsserveWeb.Presence do
  use Phoenix.Presence,
    otp_app: :wsserve,
    pubsub_server: Wsserve.PubSub
end
