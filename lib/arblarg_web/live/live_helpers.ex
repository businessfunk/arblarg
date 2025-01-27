defmodule ArblargWeb.LiveHelpers do
  import Phoenix.Component
  import Phoenix.LiveView

  def handle_community_search(socket, query) do
    searched_communities =
      if String.length(query) >= 2 do
        Arblarg.Communities.search_communities(query)
      else
        []
      end

    socket
    |> assign(:community_search, query)
    |> assign(:searched_communities, searched_communities)
  end
end
