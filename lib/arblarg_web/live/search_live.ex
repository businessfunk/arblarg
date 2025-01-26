defmodule ArblargWeb.SearchLive do
  use ArblargWeb, :live_view
  alias Arblarg.Temporal
  import ArblargWeb.PostComponents

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Arblarg.Temporal.subscribe()
    end

    {:ok, assign(socket, [
      query: "",
      results: [],
      loading: false,
      sort_by: "newest",
      min_replies: 0,
      max_age_hours: 24,
      expiring_within: "all"
    ])}
  end

  def handle_event(event, params, socket) when event in ["search"] do
    query = params["query"] || socket.assigns.query
    sort_by = params["sort_by"] || socket.assigns.sort_by
    min_replies = String.to_integer(params["min_replies"] || to_string(socket.assigns.min_replies))
    max_age_hours = String.to_integer(params["max_age_hours"] || to_string(socket.assigns.max_age_hours))
    expiring_within = params["expiring_within"] || socket.assigns.expiring_within

    if String.length(query) >= 2 do
      results = Temporal.search_posts(query)
      |> Arblarg.Repo.preload(:replies)
      |> filter_by_replies(min_replies)
      |> filter_by_age(max_age_hours)
      |> filter_by_expiration(expiring_within)
      |> sort_results(sort_by)

      {:noreply, assign(socket,
        query: query,
        sort_by: sort_by,
        min_replies: min_replies,
        max_age_hours: max_age_hours,
        expiring_within: expiring_within,
        results: results,
        loading: false)}
    else
      {:noreply, assign(socket,
        query: query,
        results: [],
        loading: false)}
    end
  end

  defp filter_by_replies(posts, min_replies) do
    Enum.filter(posts, fn post ->
      case post.replies do
        %Ecto.Association.NotLoaded{} -> false
        replies when is_list(replies) -> length(replies) >= min_replies
        _ -> false
      end
    end)
  end

  defp filter_by_age(posts, max_age_hours) do
    now = DateTime.utc_now()
    Enum.filter(posts, fn post ->
      case post.inserted_at do
        %DateTime{} = dt ->
          age_hours = DateTime.diff(now, dt) / 3600
          age_hours <= max_age_hours
        %NaiveDateTime{} = ndt ->
          dt = DateTime.from_naive!(ndt, "Etc/UTC")
          age_hours = DateTime.diff(now, dt) / 3600
          age_hours <= max_age_hours
        _ -> false
      end
    end)
  end

  defp filter_by_expiration(posts, "all"), do: posts
  defp filter_by_expiration(posts, hours) when is_binary(hours) do
    hours = String.to_integer(hours)
    now = DateTime.utc_now()
    Enum.filter(posts, fn post ->
      time_until_expiry = DateTime.diff(post.expires_at, now) / 3600
      time_until_expiry <= hours
    end)
  end

  defp sort_results(posts, "newest"), do: Enum.sort_by(posts, fn post ->
    case post.inserted_at do
      %DateTime{} = dt -> dt
      %NaiveDateTime{} = ndt -> DateTime.from_naive!(ndt, "Etc/UTC")
    end
  end, {:desc, DateTime})

  defp sort_results(posts, "oldest"), do: Enum.sort_by(posts, fn post ->
    case post.inserted_at do
      %DateTime{} = dt -> dt
      %NaiveDateTime{} = ndt -> DateTime.from_naive!(ndt, "Etc/UTC")
    end
  end, {:asc, DateTime})

  defp sort_results(posts, "most_replies"), do: Enum.sort_by(posts, &length(&1.replies || []), :desc)

  defp sort_results(posts, "expiring_soon"), do: Enum.sort_by(posts, fn post ->
    case post.expires_at do
      %DateTime{} = dt -> dt
      %NaiveDateTime{} = ndt -> DateTime.from_naive!(ndt, "Etc/UTC")
    end
  end, {:asc, DateTime})

  def handle_info({:post_created, post}, %{assigns: %{query: query}} = socket) when byte_size(query) >= 2 do
    post = Arblarg.Repo.preload(post, [:community, :replies])
    if post_matches_query?(post, query) do
      {:noreply, update(socket, :results, &[post | &1])}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:post_deleted, post_id}, socket) do
    {:noreply, update(socket, :results, &Enum.reject(&1, fn p -> p.id == post_id end))}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp post_matches_query?(post, query) do
    query = String.downcase(query)
    String.contains?(String.downcase(post.body), query) ||
      String.contains?(String.downcase(post.author), query) ||
      (post.community && String.contains?(String.downcase(post.community.name), query))
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-4">
      <div class="sticky top-0 bg-black/95 backdrop-blur-sm z-10 pb-4 border-b border-zinc-800 mb-6">
        <h1 class="text-xl font-bold text-white mb-4">Search Posts</h1>

        <form phx-submit="search" phx-change="search">
          <div class="relative mb-4">
            <input
              type="text"
              name="query"
              value={@query}
              placeholder="Search posts..."
              class="w-full bg-zinc-900 text-white border border-zinc-800 rounded-lg pl-4 pr-10 py-2"
              autocomplete="off"
            />
            <button type="submit" class="absolute right-2 top-2 text-zinc-400 hover:text-white">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div class="space-y-2">
              <label class="block text-sm font-medium text-zinc-400">Sort by</label>
              <select name="sort_by" class="w-full bg-zinc-900 text-white border border-zinc-800 rounded-lg px-3 py-2">
                <option value="newest" selected={@sort_by == "newest"}>Newest first</option>
                <option value="oldest" selected={@sort_by == "oldest"}>Oldest first</option>
                <option value="most_replies" selected={@sort_by == "most_replies"}>Most replies</option>
                <option value="expiring_soon" selected={@sort_by == "expiring_soon"}>Expiring soon</option>
              </select>
            </div>

            <div class="space-y-2">
              <label class="block text-sm font-medium text-zinc-400">Minimum replies</label>
              <select name="min_replies" class="w-full bg-zinc-900 text-white border border-zinc-800 rounded-lg px-3 py-2">
                <option value="0" selected={@min_replies == 0}>Any</option>
                <option value="1" selected={@min_replies == 1}>At least 1</option>
                <option value="5" selected={@min_replies == 5}>At least 5</option>
                <option value="10" selected={@min_replies == 10}>At least 10</option>
              </select>
            </div>

            <div class="space-y-2">
              <label class="block text-sm font-medium text-zinc-400">Post age</label>
              <select name="max_age_hours" class="w-full bg-zinc-900 text-white border border-zinc-800 rounded-lg px-3 py-2">
                <option value="24" selected={@max_age_hours == 24}>Last 24 hours</option>
                <option value="48" selected={@max_age_hours == 48}>Last 48 hours</option>
                <option value="72" selected={@max_age_hours == 72}>Last 72 hours</option>
                <option value="168" selected={@max_age_hours == 168}>Last week</option>
              </select>
            </div>

            <div class="space-y-2">
              <label class="block text-sm font-medium text-zinc-400">Expiring within</label>
              <select name="expiring_within" class="w-full bg-zinc-900 text-white border border-zinc-800 rounded-lg px-3 py-2">
                <option value="all" selected={@expiring_within == "all"}>Any time</option>
                <option value="1" selected={@expiring_within == "1"}>1 hour</option>
                <option value="3" selected={@expiring_within == "3"}>3 hours</option>
                <option value="6" selected={@expiring_within == "6"}>6 hours</option>
                <option value="12" selected={@expiring_within == "12"}>12 hours</option>
              </select>
            </div>
          </div>
        </form>
      </div>

      <div :if={@loading} class="text-center py-8">
        <div class="animate-pulse text-zinc-500">Searching...</div>
      </div>

      <div :if={Enum.empty?(@results) and not @loading} class="text-center py-8">
        <p class="text-zinc-500">No results found</p>
      </div>

      <div :if={not Enum.empty?(@results)} class="space-y-6">
        <%= for post <- @results do %>
          <.link
            navigate={get_post_path(post)}
            class="block hover:bg-zinc-800 cursor-pointer"
          >
            <div class="bg-zinc-900 rounded-lg p-4 border border-zinc-800 hover:border-zinc-700">
              <.post_header
                author={post.author}
                id={post.id}
                inserted_at={post.inserted_at}
                expires_at={post.expires_at}
              />
              <div class="mt-3 text-white break-words">
                <%= post.body %>
              </div>
              <.link_preview
                :if={post.link}
                link={post.link}
                link_title={post.link_title}
                link_description={post.link_description}
                link_image={post.link_image}
                link_domain={post.link_domain}
              />
            </div>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  defp get_post_path(post) do
    if post.community do
      ~p"/c/#{post.community.slug}/posts/#{post.id}"
    else
      ~p"/posts/#{post.id}"
    end
  end
end
