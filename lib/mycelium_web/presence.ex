defmodule MyceliumWeb.Presence do
  use Phoenix.Presence,
    otp_app: :mycelium,
    pubsub_server: Mycelium.PubSub
end
