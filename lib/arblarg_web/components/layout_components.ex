defmodule ArblargWeb.LayoutComponents do
  use ArblargWeb, :html

  def sidebar_layout(assigns) do
    assigns = assign_new(assigns, :community_search, fn -> "" end)
    assigns = assign_new(assigns, :searched_communities, fn -> [] end)
    assigns = assign_new(assigns, :popular_communities, fn ->
      Arblarg.Communities.list_popular_communities(5)
    end)

    ~H"""
    <div class="relative mx-auto max-w-7xl px-4 py-4">
      <div class="grid grid-cols-12 gap-6">
        <!-- Left Sidebar -->
        <div class="hidden lg:block lg:col-span-3">
          <div class="sticky top-20">
            <div class="space-y-4 max-h-[calc(100vh-6rem)] overflow-y-auto">
              <div class="bg-zinc-900 rounded-lg border border-zinc-800 p-4">
                <h3 class="text-sm font-medium text-white mb-3">Quick Links</h3>
                <div class="space-y-2">
                  <.link
                    navigate={~p"/"}
                    class={"flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm #{if !@current_community, do: "bg-zinc-800 text-white", else: "text-zinc-400 hover:text-white hover:bg-zinc-800/50"} transition-colors"}>
                    <span>Global Feed</span>
                  </.link>
                  <.link
                    navigate={~p"/tracked"}
                    class="flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-zinc-400 hover:text-white hover:bg-zinc-800/50 transition-colors">
                    <span>Tracked Posts</span>
                  </.link>
                </div>
              </div>

              <div class="bg-zinc-900 rounded-lg border border-zinc-800 p-4">
                <h3 class="text-sm font-medium text-white mb-3">Popular Communities</h3>
                <div class="space-y-2">
                  <%= for community <- @popular_communities do %>
                    <.link
                      navigate={~p"/c/#{community.slug}"}
                      class={"flex items-center justify-between px-2 py-1.5 rounded-lg text-sm #{if @current_community && @current_community.id == community.id, do: "bg-zinc-800 text-white", else: "text-zinc-400 hover:text-white hover:bg-zinc-800/50"} transition-colors"}>
                      <span><%= community.name %></span>
                      <span class="text-xs text-zinc-500"><%= community.post_count %> posts</span>
                    </.link>
                  <% end %>
                </div>
              </div>

              <%= if length(@trending_posts) > 0 do %>
                <.trending_posts posts={@trending_posts} />
              <% end %>
            </div>
          </div>
        </div>

        <!-- Main Content -->
        <div class="col-span-12 lg:col-span-6 min-h-[calc(100vh-6rem)]">
          <%= render_slot(@inner_block) %>
        </div>

        <!-- Right Sidebar -->
        <div class="hidden lg:block lg:col-span-3">
          <div class="sticky top-20">
            <div class="space-y-4 max-h-[calc(100vh-6rem)] overflow-y-auto">
              <.live_component
                module={ArblargWeb.ShoutboxLive}
                id={"shoutbox-#{@current_community && @current_community.id || "global"}"}
                user_id={@user_id}
                community_id={@current_community && @current_community.id}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def trending_posts(assigns) do
    ~H"""
    <div class="bg-zinc-900 rounded-lg border border-zinc-800 p-4 mt-4">
      <h3 class="text-sm font-medium text-white mb-3">Trending Posts</h3>
      <div class="space-y-3">
        <%= for post <- @posts do %>
          <.link
            navigate={post.community_id && ~p"/c/#{post.community.slug}/posts/#{post.id}" || ~p"/posts/#{post.id}"}
            class="block group">
            <div class="text-sm text-zinc-400 group-hover:text-white transition-colors line-clamp-2">
              <%= if post.body && post.body != "" do %>
                <%= post.body %>
              <% else %>
                <%= post.link_title || post.link_domain %>
              <% end %>
            </div>
            <div class="flex items-center gap-2 mt-1">
              <span class="text-xs text-zinc-500">
                <%= post.author %>
              </span>
              <span class="text-xs text-zinc-600">•</span>
              <%= if post.community_id do %>
                <span class="text-xs text-zinc-500">
                  <%= post.community.name %>
                </span>
                <span class="text-xs text-zinc-600">•</span>
              <% end %>
              <span class="text-xs text-zinc-500">
                <%= length(post.replies) %> replies
              </span>
            </div>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  def quick_links(assigns) do
    ~H"""
    <div class="bg-zinc-900 rounded-lg border border-zinc-800 p-4 mt-4">
      <h3 class="text-sm font-medium text-white mb-3">Quick Links</h3>
      <div class="space-y-2">
        <.link
          navigate={~p"/tracked"}
          class="flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-zinc-400 hover:text-white hover:bg-zinc-800/50 transition-colors">
          <span>Tracked Posts</span>
        </.link>
      </div>
    </div>
    """
  end
end
