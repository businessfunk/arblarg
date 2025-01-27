defmodule ArblargWeb.Layouts.SidebarLayout do
  use ArblargWeb, :html

  import Phoenix.Component

  def sidebar_layout(assigns) do
    assigns = assign_new(assigns, :community_search, fn -> "" end)
    assigns = assign_new(assigns, :searched_communities, fn -> [] end)
    assigns = assign_new(assigns, :popular_communities, fn ->
      Arblarg.Communities.list_popular_communities(5)
    end)

    ~H"""
    <!-- existing template code -->
    """
  end
end
