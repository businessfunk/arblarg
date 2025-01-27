defmodule Arblarg.Temporal.PostInteraction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Arblarg.Temporal.Post

  schema "post_interactions" do
    field :session_id, :string
    belongs_to :post, Post

    timestamps()
  end

  def changeset(interaction, attrs) do
    interaction
    |> cast(attrs, [:session_id, :post_id])
    |> validate_required([:session_id, :post_id])
    |> validate_length(:session_id, max: 255)
    |> unique_constraint([:session_id, :post_id])
  end
end
