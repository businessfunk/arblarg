defmodule Arblarg.Repo.Migrations.AddSaltToShouts do
  use Ecto.Migration

  def change do
    alter table(:shouts) do
      add :author_salt, :string, null: false, default: fragment("md5(random()::text)")
      modify :author, :string, null: false
      modify :message, :string, null: false
    end

    create index(:shouts, [:community_id])
  end
end
