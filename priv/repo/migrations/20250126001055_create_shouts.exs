defmodule Arblarg.Repo.Migrations.CreateShouts do
  use Ecto.Migration

  def change do
    create table(:shouts) do
      add :message, :string, null: false
      add :author, :string, null: false

      timestamps()
    end

    create index(:shouts, [:inserted_at])
  end
end
