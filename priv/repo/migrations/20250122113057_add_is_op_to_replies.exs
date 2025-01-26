defmodule Arblarg.Repo.Migrations.AddIsOpToReplies do
  use Ecto.Migration

  def change do
    alter table(:replies) do
      add :is_op, :boolean, default: false, null: false
    end
  end
end
