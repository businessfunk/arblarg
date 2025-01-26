defmodule Arblarg.Repo.Migrations.AddYoutubeFieldsToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :is_youtube, :boolean, default: false
      add :youtube_id, :string
    end
  end
end
