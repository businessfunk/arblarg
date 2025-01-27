defmodule Arblarg.Repo.Migrations.CreatePostInteractions do
  use Ecto.Migration

  def change do
    create table(:post_interactions) do
      add :session_id, :string, null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:post_interactions, [:session_id, :post_id])
    create index(:post_interactions, [:session_id])
    create index(:post_interactions, [:post_id])
  end
end
