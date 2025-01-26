defmodule Arblarg.Repo.Migrations.AddLinkMetadataToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :link_title, :string
      add :link_description, :text
      add :link_image, :string
      add :link_domain, :string
    end
  end
end
