defmodule Arblarg.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :body, :text, null: false
      add :author, :string
      add :expires_at, :utc_datetime, null: false

      timestamps()
    end

    create index(:posts, [:expires_at])
  end
end