defmodule Arblarg.Repo.Migrations.MakePostBodyOptional do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      modify :body, :text, null: true
    end
  end
end
