defmodule Arblarg.Repo.Migrations.AddLinkToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :link, :string
    end
  end
end
