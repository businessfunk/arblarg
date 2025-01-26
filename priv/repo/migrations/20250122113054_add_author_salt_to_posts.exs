defmodule Arblarg.Repo.Migrations.AddAuthorSaltToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :author_salt, :string, null: false, default: fragment("md5(random()::text)")
    end
  end
end
