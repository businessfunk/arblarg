defmodule Arblarg.Temporal.Shout do
  use Ecto.Schema
  import Ecto.Changeset
  alias Arblarg.Communities.Community

  schema "shouts" do
    field :message, :string
    field :author, :string
    field :author_salt, :string
    field :expires_at, :utc_datetime
    belongs_to :community, Community

    timestamps()
  end

  def changeset(shout, attrs) do
    shout
    |> cast(attrs, [:message, :author, :author_salt, :community_id, :expires_at])
    |> validate_required([:message, :author, :author_salt, :expires_at])
    |> validate_length(:message, min: 1, max: 500, message: "must be between 1 and 500 characters")
    |> sanitize_message()
    |> foreign_key_constraint(:community_id, message: "community no longer exists")
    |> validate_expire_time()
  end

  defp sanitize_message(changeset) do
    if message = get_change(changeset, :message) do
      put_change(changeset, :message, message)
    else
      changeset
    end
  end

  defp validate_expire_time(changeset) do
    case get_change(changeset, :expires_at) do
      nil ->
        # Default to 24 hours if not specified
        put_change(changeset, :expires_at, DateTime.utc_now() |> DateTime.add(24, :hour))
      expires_at ->
        now = DateTime.utc_now()
        hours_diff = DateTime.diff(expires_at, now, :hour)
        if hours_diff > 0 and hours_diff <= 24 do
          changeset
        else
          add_error(changeset, :expires_at, "must be within 24 hours")
        end
    end
  end
end
