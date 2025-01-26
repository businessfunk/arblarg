defmodule Arblarg.Repo.Migrations.CreateReplies do
  use Ecto.Migration

  def change do
    create table(:replies) do
      add :body, :text, null: false
      add :author, :string
      add :post_id, references(:posts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:replies, [:post_id])
  end
end
