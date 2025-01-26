defmodule Arblarg.Temporal.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Arblarg.Temporal.Reply
  alias Arblarg.LinkMetadata
  alias Arblarg.Communities.Community

  schema "posts" do
    field :body, :string
    field :author, :string
    field :author_salt, :string
    field :is_op, :boolean, virtual: true
    field :link, :string
    field :link_title, :string
    field :link_description, :string
    field :link_image, :string
    field :link_domain, :string
    field :is_youtube, :boolean, default: false
    field :youtube_id, :string
    field :expires_at, :utc_datetime
    belongs_to :community, Community
    has_many :replies, Reply, preload_order: [desc: :inserted_at]

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:body, :link, :author, :author_salt, :expires_at, :community_id,
                    :is_youtube, :youtube_id, :link_title, :link_description, :link_image, :link_domain])
    |> validate_required([:author, :author_salt, :expires_at])
    |> validate_content()
    |> validate_link()
    |> fetch_link_metadata()
    |> validate_expire_time()
    |> foreign_key_constraint(:community_id)
  end

  defp validate_content(changeset) do
    case {get_change(changeset, :body), get_change(changeset, :link)} do
      {nil, nil} ->
        add_error(changeset, :body, "either body or link is required", validation: :required)
      {nil, link} when is_binary(link) ->
        # If only link is provided, use it as the body too
        put_change(changeset, :body, link)
      {body, _} when is_binary(body) ->
        validate_length(changeset, :body, max: 5000,
          message: "must be at most 5000 characters")
      {_, _} ->
        changeset
    end
  end

  defp validate_link(changeset) do
    if link = get_change(changeset, :link) do
      case Arblarg.LinkMetadata.validate_url(link) do
        {:ok, _} -> changeset
        {:error, message} -> add_error(changeset, :link, message)
      end
    else
      changeset
    end
  end

  defp fetch_link_metadata(changeset) do
    with true <- changeset.valid?,
         link when not is_nil(link) <- get_change(changeset, :link),
         {:ok, metadata} <- LinkMetadata.fetch(link) do
      changeset
      |> put_change(:link_title, metadata.title)
      |> put_change(:link_description, metadata.description)
      |> put_change(:link_image, metadata.image)
      |> put_change(:link_domain, metadata.domain)
      |> put_change(:is_youtube, metadata.is_youtube)
      |> put_change(:youtube_id, metadata.youtube_id)
    else
      {:error, _} -> changeset
      _ -> changeset
    end
  end

  defp validate_expire_time(changeset) do
    case get_change(changeset, :expires_at) do
      nil ->
        # Default to 24 hours if not specified
        put_change(changeset, :expires_at, DateTime.utc_now() |> DateTime.add(24, :hour))
      expires_at ->
        now = DateTime.utc_now()
        hours_diff = DateTime.diff(expires_at, now, :hour)
        if hours_diff > 0 and hours_diff <= 168 do
          changeset
        else
          add_error(changeset, :expires_at, "must be between 1 hour and 7 days from now")
        end
    end
  end
end
