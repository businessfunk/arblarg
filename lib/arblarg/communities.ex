defmodule Arblarg.Communities do
  import Ecto.Query
  alias Arblarg.Repo
  alias Arblarg.Communities.Community

  def get_default_community do
    get_community!("general")
  end

  def list_communities do
    Repo.all(from c in Community, order_by: c.name)
  end

  def get_community!(slug) when is_binary(slug) do
    Repo.get_by!(Community, slug: slug)
  end

  def get_community_by_id!(id) do
    Repo.get!(Community, id)
  end

  def create_community(attrs) do
    %Community{}
    |> Community.changeset(attrs)
    |> Repo.insert()
  end

  def update_community(%Community{} = community, attrs) do
    community
    |> Community.changeset(attrs)
    |> Repo.update()
  end

  def delete_community(%Community{} = community) do
    Repo.delete(community)
  end

  def change_community(%Community{} = community, attrs \\ %{}) do
    Community.changeset(community, attrs)
  end
end
