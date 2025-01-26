defmodule Arblarg.Communities.Community do
  use Ecto.Schema
  import Ecto.Changeset
  alias Arblarg.Temporal.Post

  schema "communities" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :rules, :string
    field :creator_id, :string
    has_many :posts, Post

    timestamps()
  end

  def changeset(community, attrs) do
    community
    |> cast(attrs, [:name, :slug, :description, :rules, :creator_id])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 3, max: 50)
    |> validate_length(:description, max: 500)
    |> validate_length(:rules, max: 1000)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "only lowercase letters, numbers, and dashes allowed")
    |> unique_constraint(:slug)
  end
end
