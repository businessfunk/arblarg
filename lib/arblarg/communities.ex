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

  def list_popular_communities(limit \\ 5) do
    from(c in Community,
      left_join: p in assoc(c, :posts),
      group_by: c.id,
      order_by: [desc: count(p.id)],
      limit: ^limit,
      select: %{c | post_count: count(p.id)}
    )
    |> Repo.all()
  end

  def search_communities(query) when is_binary(query) do
    search_term = "%#{query}%"

    Repo.all(
      from c in Community,
      where: ilike(c.name, ^search_term) or ilike(c.description, ^search_term),
      order_by: c.name,
      limit: 10
    )
  end
  def search_communities(_), do: []
end
