defmodule Mycelium.Repo do
  use Ecto.Repo,
    otp_app: :mycelium,
    adapter: Ecto.Adapters.Postgres
end
