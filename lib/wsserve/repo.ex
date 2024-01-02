defmodule Wsserve.Repo do
  use Ecto.Repo,
    otp_app: :wsserve,
    adapter: Ecto.Adapters.Postgres
end
