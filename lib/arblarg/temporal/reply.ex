defmodule Arblarg.Temporal.Reply do
  use Ecto.Schema
  import Ecto.Changeset

  schema "replies" do
    field :body, :string
    field :author, :string
    field :is_op, :boolean, default: false
    belongs_to :post, Arblarg.Temporal.Post

    timestamps()
  end

  def changeset(reply, attrs) do
    reply
    |> cast(attrs, [:body, :author, :post_id, :is_op])
    |> validate_required([:body, :post_id], message: "can't be blank")
    |> validate_length(:body, min: 2,
        message: "must be at least 2 characters")
    |> validate_length(:body, max: 5000,
        message: "must be less than 5000 characters")
    |> validate_format(:body, ~r/[[:graph:]]/,
        message: "must contain at least one non-whitespace character")
    |> foreign_key_constraint(:post_id, message: "post no longer exists")
  end
end
