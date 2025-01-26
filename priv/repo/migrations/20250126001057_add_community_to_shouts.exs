defmodule Arblarg.Repo.Migrations.AddCommunityToShouts do
  use Ecto.Migration

  def change do
    alter table(:shouts) do
      add :community_id, references(:communities), null: true  # null means global shoutbox
    end

    create index(:shouts, [:community_id])
  end
end
