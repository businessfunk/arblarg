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
    |> validate_length(:body, min: 2, max: 5000,
        message: "must be between 2 and 5000 characters")
    |> foreign_key_constraint(:post_id, message: "post no longer exists")
  end
end
