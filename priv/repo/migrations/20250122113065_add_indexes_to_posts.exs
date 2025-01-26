defmodule Arblarg.Repo.Migrations.AddIndexesToPosts do
  use Ecto.Migration

  def change do
    # Add composite index for common queries
    create index(:posts, [:expires_at, :inserted_at])

    # Add index for timestamp queries
    create index(:posts, [:inserted_at])
    create index(:replies, [:inserted_at])
  end
end
