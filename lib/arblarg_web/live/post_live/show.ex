defmodule ArblargWeb.PostLive.Show do
  use ArblargWeb, :live_view
  alias Arblarg.{Temporal, UserIdentity}
  alias Arblarg.Temporal.Reply
  import ArblargWeb.PostComponents
  require Logger
  alias Arblarg.RateLimiter
  alias Arblarg.HtmlSanitizer
  import ArblargWeb.LayoutComponents
  import ArblargWeb.LiveHelpers
  on_mount ArblargWeb.Live.Hooks.SidebarHooks

  @impl true
  def mount(%{"id" => id}, session, socket) do
    if connected?(socket) do
      Temporal.subscribe()
      Temporal.subscribe_to_trending()
    end

    session_id = session["user_id"]

    case Temporal.get_post(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Post not found or has expired")
         |> redirect(to: ~p"/")}

      post ->
        post = Arblarg.Repo.preload(post, :community)
        {op_name, _} = UserIdentity.generate_tripcode(session["user_id"], post.author_salt)
        is_op = post.author == op_name

        {thread_identity, _is_op} = UserIdentity.generate_tripcode(
          session["user_id"],
          post.author_salt || "default",
          [],
          is_op: is_op
        )

        # Create a title from the post body or link title
        page_title = cond do
          post.link_title && post.link_title != "" -> post.link_title
          post.body && post.body != "" -> String.slice(post.body, 0, 50) <> if String.length(post.body) > 50, do: "...", else: ""
          true -> "Post ##{post.id}"
        end

        # Subscribe to shoutbox if connected
        if connected?(socket) do
          topic = Temporal.shoutbox_topic(post.community_id)
          Phoenix.PubSub.subscribe(Arblarg.PubSub, topic)
        end

        # Get trending posts for the current community
        trending_posts = case post.community_id do
          nil -> Temporal.list_trending_posts(limit: 5)
          id -> Temporal.list_trending_posts(limit: 5, community_id: id)
        end

        {:ok,
         socket
         |> assign(:page_title, page_title)
         |> assign(:post, post)
         |> assign(:thread_identity, thread_identity)
         |> assign(:user_id, session_id)
         |> assign(:community, post.community)
         |> assign(:trending_posts, trending_posts)
         |> assign(:reply_forms, %{post.id => to_form(Temporal.change_reply(%Reply{}))})}
    end
  end

  @impl true
  def handle_event("reply", %{"post-id" => post_id, "reply" => %{"body" => body}}, socket) do
    require Logger
    Logger.debug("Creating reply - Post ID: #{inspect(post_id)}, User ID: #{inspect(socket.assigns.user_id)}")

    # Trim whitespace from body
    body = String.trim(body)

    reply_params = %{"body" => body}
    reply_params = Map.put(reply_params, "author", socket.assigns.thread_identity)
    reply_params = Map.put(reply_params, "is_op", socket.assigns.post.author == socket.assigns.thread_identity)

    case Temporal.create_reply(post_id, reply_params, socket.assigns.user_id) do
      {:ok, _reply} ->
        case Temporal.track_interaction(socket.assigns.user_id, post_id) do
          {:ok, interaction} ->
            Logger.debug("Interaction tracked successfully: #{inspect(interaction)}")
            {:noreply,
             socket
             |> put_flash(:info, "Reply posted")
             |> update(:reply_forms, fn forms ->
               Map.put(forms, post_id, to_form(%{"body" => ""}))
             end)}
          {:error, changeset} ->
            Logger.debug("Failed to track interaction: #{inspect(changeset.errors)}")
            {:noreply,
             socket
             |> put_flash(:error, "Failed to track interaction")
             |> update(:reply_forms, fn forms ->
               Map.put(forms, post_id, to_form(%{"body" => ""}))
             end)}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.debug("Reply creation failed: #{inspect(changeset.errors)}")
        {:noreply,
         socket
         |> put_flash(:error, "Reply #{translate_error(hd(changeset.errors[:body]))}")
         |> update(:reply_forms, fn forms ->
           Map.put(forms, post_id, to_form(changeset))
         end)}
    end
  end

  @impl true
  def handle_info({:post_updated, post}, socket) do
    if post.id == socket.assigns.post.id do
      post = Arblarg.Repo.preload(post, :community)
      {:noreply, assign(socket, :post, post)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:post_expired, post_id}, socket) do
    if post_id == socket.assigns.post.id do
      {:noreply,
       socket
       |> put_flash(:info, "This post has expired")
       |> redirect(to: ~p"/")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:trending_updated, community_id, trending_posts}, socket) do
    # Only update if it matches our current view (global or specific community)
    if (community_id == nil && !socket.assigns.post.community_id) ||
       (socket.assigns.post.community_id == community_id) do
      {:noreply, assign(socket, :trending_posts, trending_posts)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search-communities", %{"query" => query}, socket) do
    {:noreply, handle_community_search(socket, query)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp get_user_id(session, socket) do
    case session["user_id"] do
      nil ->
        ip = socket.assigns.client_ip || "127.0.0.1"
        ip_string = :inet.ntoa(ip) |> to_string()
        "ip_#{ip_string}"
      user_id ->
        user_id
    end
  end

  defp render_post_content(post, socket) do
    # Your existing post rendering logic
    # This helps keep the template clean by moving complex rendering logic here
  end
end
