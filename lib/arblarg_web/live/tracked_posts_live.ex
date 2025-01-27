defmodule ArblargWeb.TrackedPostsLive do
  use ArblargWeb, :live_view
  alias Arblarg.Temporal
  require Logger

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Temporal.subscribe()
      # Also subscribe to interaction updates
      Phoenix.PubSub.subscribe(Arblarg.PubSub, "user_interactions:#{session["user_id"]}")
    end

    session_id = session["user_id"]

    # Debug logging
    Logger.debug("Session ID: #{inspect(session_id)}")
    posts = fetch_tracked_posts(session_id)
    Logger.debug("Found posts: #{inspect(posts)}")

    {:ok,
     socket
     |> assign(:page_title, "Tracked Posts")
     |> assign(:posts, posts)
     |> assign(:user_id, session_id)}
  end

  @impl true
  def handle_info({:interaction_created, post_id}, %{assigns: %{user_id: user_id}} = socket) do
    case Temporal.get_post(post_id) do
      nil ->
        {:noreply, socket}
      post ->
        post = Arblarg.Repo.preload(post, :community)
        if not Enum.any?(socket.assigns.posts, &(&1.id == post_id)) do
          {:noreply, assign(socket, :posts, [post | socket.assigns.posts])}
        else
          {:noreply, socket}
        end
    end
  end

  def handle_info({:post_created, _post}, socket) do
    # We don't need to do anything when a post is created
    {:noreply, socket}
  end

  def handle_info({:post_expired, post_id}, socket) do
    {:noreply,
     assign(socket, :posts, Enum.reject(socket.assigns.posts, &(&1.id == post_id)))}
  end

  def handle_info({:post_updated, post}, socket) do
    if Enum.any?(socket.assigns.posts, &(&1.id == post.id)) do
      post = Arblarg.Repo.preload(post, :community)

      updated_posts =
        Enum.map(socket.assigns.posts, fn p ->
          if p.id == post.id, do: post, else: p
        end)

      {:noreply, assign(socket, :posts, updated_posts)}
    else
      {:noreply, socket}
    end
  end

  # Add this to periodically clean expired posts from the tracked list
  @impl true
  def handle_info(:cleanup_expired, socket) do
    now = DateTime.utc_now()
    active_posts = Enum.filter(socket.assigns.posts, fn post ->
      DateTime.compare(post.expires_at, now) == :gt
    end)

    if length(active_posts) != length(socket.assigns.posts) do
      {:noreply, assign(socket, :posts, active_posts)}
    else
      {:noreply, socket}
    end
  end

  # Catch-all handler for any other messages
  def handle_info(_, socket), do: {:noreply, socket}

  defp fetch_tracked_posts(user_id) do
    Temporal.list_user_interactions(user_id)
    |> Arblarg.Repo.preload(:community)
  end

  defp get_user_id(session, socket) do
    case session["user_id"] do
      nil ->
        ip = socket.assigns.client_ip || "127.0.0.1"
        ip_string = :inet.ntoa(ip) |> to_string()
        "ip_#{ip_string}"
      user_id -> user_id
    end
  end
end
