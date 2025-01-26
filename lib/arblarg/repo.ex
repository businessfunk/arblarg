defmodule Arblarg.Repo do
  use Ecto.Repo,
    otp_app: :arblarg,
    adapter: Ecto.Adapters.Postgres
end
