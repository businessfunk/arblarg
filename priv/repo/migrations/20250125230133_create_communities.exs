defmodule Arblarg.Repo.Migrations.CreateCommunities do
  use Ecto.Migration

  def change do
    create table(:communities) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :rules, :text
      add :creator_id, :string

      timestamps()
    end

    create unique_index(:communities, [:slug])

    alter table(:posts) do
      add :community_id, references(:communities, on_delete: :delete_all)
    end

    create index(:posts, [:community_id])
  end
end
