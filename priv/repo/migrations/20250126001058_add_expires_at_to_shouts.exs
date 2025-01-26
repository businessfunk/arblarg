defmodule Arblarg.Repo.Migrations.AddExpiresAtToShouts do
  use Ecto.Migration

  def change do
    # First add the column as nullable
    alter table(:shouts) do
      add :expires_at, :utc_datetime
    end

    # Set default expiration for existing records (24 hours from now)
    execute """
    UPDATE shouts
    SET expires_at = NOW() + INTERVAL '24 hours'
    WHERE expires_at IS NULL
    """

    # Now make it non-nullable
    alter table(:shouts) do
      modify :expires_at, :utc_datetime, null: false
    end

    create index(:shouts, [:expires_at])
  end
end
