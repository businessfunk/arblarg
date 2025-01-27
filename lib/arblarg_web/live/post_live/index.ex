defmodule ArblargWeb.PostLive.Index do
  use ArblargWeb, :live_view
  alias Arblarg.{Temporal, UserIdentity, Communities}
  alias Arblarg.Temporal.{Post, Reply}
  alias Arblarg.RateLimiter
  alias Arblarg.HtmlSanitizer

  @posts_per_page 20

  @impl true
  def mount(params, session, socket) do
    user_id = get_user_id(session, socket)

    connected = connected?(socket)

    if connected?(socket) do
      # Subscribe to posts channel
      Temporal.subscribe()

      # Also subscribe to shoutbox
      topic = Temporal.shoutbox_topic(nil)
      Phoenix.PubSub.subscribe(Arblarg.PubSub, topic)
    end

    {posts, community} = case params do
      %{"community_slug" => slug} ->
        community = Communities.get_community!(slug)
        {Temporal.list_active_posts(community_id: community.id, limit: @posts_per_page), community}

      _ ->
        # Global feed - show all posts
        {Temporal.list_active_posts(limit: @posts_per_page), nil}
    end

    reply_forms = create_reply_forms(posts)

    trending_posts = Temporal.list_trending_posts(limit: 5)

    {:ok,
     socket
     |> assign(:page_title, "Posts")
     |> assign(:user_id, user_id)
     |> assign(:posts, posts)
     |> assign(:community, community)
     |> assign(:trending_posts, trending_posts)
     |> assign(:reply_forms, reply_forms)
     |> assign(:form, to_form(Temporal.change_post(%Post{})))
     |> assign(:has_more, length(posts) >= @posts_per_page)
     |> assign(:post_count, length(posts))
     |> assign(:connected, connected)
     |> stream(:posts, posts)
     |> assign(:page, 1)
     |> assign(:per_page, 10)}
  end

  @impl true
  def handle_event("create", %{"post" => post_params, "expire_hours" => hours, "community_id" => community_id}, socket) do
    random_salt = :crypto.strong_rand_bytes(16) |> Base.url_encode64()
    {author, _} = UserIdentity.generate_tripcode(socket.assigns.user_id, random_salt, [], is_op: true)

    expires_at =
      DateTime.utc_now()
      |> DateTime.add(String.to_integer(hours) * 3600)

    params = post_params
    |> Map.merge(%{
      "author" => author,
      "author_salt" => random_salt,
      "expires_at" => expires_at
    })

    # Only add community_id if it's not "global"
    params = if community_id == "home", do: params, else: Map.put(params, "community_id", community_id)

    case Temporal.create_post(params, socket.assigns.user_id) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Posted successfully")
         |> assign(:form, to_form(%{"body" => "", "link" => ""}))}

      {:error, :rate_limit} ->
        {:noreply,
         socket
         |> put_flash(:error, "You're posting too quickly. Please wait a moment.")
         |> assign(:form, to_form(post_params))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      %Post{}
      |> Temporal.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  # Add this clause to handle the form submission with different parameter format
  def handle_event("create", %{"body" => body, "link" => link, "community_id" => community_id, "expire_hours" => hours}, socket) do
    random_salt = :crypto.strong_rand_bytes(16) |> Base.url_encode64()
    {author, _} = UserIdentity.generate_tripcode(socket.assigns.user_id, random_salt, [], is_op: true)

    expires_at =
      DateTime.utc_now()
      |> DateTime.add(String.to_integer(hours) * 3600)

    params = %{
      "body" => body,
      "link" => link,
      "author" => author,
      "author_salt" => random_salt,
      "expires_at" => expires_at
    }

    # Only add community_id if it's not "global"
    params = if community_id == "home", do: params, else: Map.put(params, "community_id", community_id)

    case Temporal.create_post(params, socket.assigns.user_id) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Posted successfully")
         |> assign(:form, to_form(Temporal.change_post(%Post{})))}

      {:error, :rate_limit} ->
        {:noreply,
         socket
         |> put_flash(:error, "You're posting too quickly. Please wait a moment.")
         |> assign(:form, to_form(%{"body" => body, "link" => link}))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("load-more", _, socket) do
    %{page: page, has_more: has_more} = socket.assigns

    if has_more do
      offset = page * @posts_per_page
      posts = case socket.assigns.community do
        nil ->
          Temporal.list_active_posts(limit: @posts_per_page, offset: offset)
        community ->
          Temporal.list_active_posts(
            community_id: community.id,
            limit: @posts_per_page,
            offset: offset
          )
      end

      {:noreply,
       socket
       |> stream(:posts, posts, at: -1)
       |> assign(:page, page + 1)
       |> assign(:has_more, length(posts) == @posts_per_page)
       |> assign(:reply_forms, Map.merge(socket.assigns.reply_forms, create_reply_forms(posts)))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("stress_test", params, socket) do
    if Mix.env() == :dev do
      mode = params["mode"]
      require Logger
      Logger.info("Starting stress test: #{mode} mode")

      Task.start(fn ->
        try do
          case mode do
            "normal" ->
              create_test_posts(500, 3000) # 500 posts over 3 seconds
            "extreme" ->
              # 10k posts over 60 seconds = ~167 posts per second
              create_test_posts(10_000, 60_000)
          end
        rescue
          e ->
            Logger.error("Stress test failed: #{inspect(e)}")
            Logger.error(Exception.format_stacktrace())
        end
      end)

      message = if mode == "normal", do: "Creating 500 posts...", else: "Creating 10,000 posts (1 minute)..."
      {:noreply, put_flash(socket, :info, message)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reply", %{"post-id" => post_id, "reply" => %{"body" => body}}, socket) do
    # Get the post to use its author_salt
    post = Temporal.get_post!(post_id)

    # Generate what would be the OP's name to compare
    {op_name, _} = UserIdentity.generate_tripcode(socket.assigns.user_id, post.author_salt)

    # Check if this user is the OP by comparing the names
    is_op = post.author == op_name

    # Generate the reply author name with OP status
    {author, _} = UserIdentity.generate_tripcode(
      socket.assigns.user_id,
      post.author_salt || "default",
      [],
      is_op: is_op
    )

    reply_params = %{
      "body" => body,
      "author" => author,
      "is_op" => is_op
    }

    case Temporal.create_reply(post_id, reply_params, socket.assigns.user_id) do
      {:ok, _reply} ->
        {:noreply,
         socket
         |> put_flash(:info, "Reply posted")
         |> update(:reply_forms, fn forms ->
           Map.put(forms, post_id, to_form(%{"body" => ""}))
         end)}

      {:error, :rate_limit} ->
        {:noreply,
         socket
         |> put_flash(:error, "You're replying too quickly. Please wait a moment.")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> update(:reply_forms, fn forms ->
           Map.put(forms, post_id, to_form(changeset))
         end)}
    end
  end

  @impl true
  def handle_info({:post_created, post}, socket) do
    post = post |> Arblarg.Repo.preload(:community)
    reply_forms = Map.put(socket.assigns.reply_forms, post.id, to_form(Temporal.change_reply(%Reply{})))

    {:noreply,
     socket
     |> assign(:reply_forms, reply_forms)
     |> assign(:post_count, socket.assigns.post_count + 1)
     |> stream_insert(:posts, post, at: 0)}
  end

  @impl true
  def handle_info({:post_expired, post_id}, socket) do
    reply_forms = Map.delete(socket.assigns.reply_forms, post_id)
    {:noreply,
     socket
     |> assign(:reply_forms, reply_forms)
     |> assign(:post_count, socket.assigns.post_count - 1)
     |> stream_delete(:posts, %{id: post_id})}
  end

  @impl true
  def handle_info({:post_updated, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post)}
  end

  @impl true
  def handle_info({:shout_created, shout}, socket) do
    # Only broadcast if the shout belongs to the current community context
    current_community_id = socket.assigns.community && socket.assigns.community.id
    if shout.community_id == current_community_id do
      send_update(ArblargWeb.ShoutboxLive,
        id: "shoutbox-#{current_community_id || "global"}",
        new_shout: shout
      )
    end

    {:noreply, socket}
  end

  defp create_test_posts(count, duration_ms) do
    delay_ms = trunc(duration_ms / count)

    Enum.each(1..count, fn i ->
      Process.sleep(delay_ms)

      expires_at = DateTime.utc_now() |> DateTime.add(24 * 3600, :second)
      random_salt = :crypto.strong_rand_bytes(16) |> Base.url_encode64()

      params = %{
        "body" => """
        Stress test post #{i}
        #{String.duplicate("Lorem ipsum dolor sit amet. ", 3)}
        Test mode: #{if count > 1000, do: "extreme", else: "normal"}
        Rate: #{trunc(count * 1000 / duration_ms)} posts/second
        """,
        "expires_at" => expires_at,
        "author" => "StressBot",
        "author_salt" => random_salt
      }

      # Use create_post! which bypasses rate limiting for stress tests
      {:ok, post} = Arblarg.Temporal.create_post!(params)
      Phoenix.PubSub.broadcast(Arblarg.PubSub, "posts", {:post_created, post})
    end)
  end

  defp create_reply_forms(posts) do
    posts
    |> Enum.map(fn post -> {post.id, to_form(Temporal.change_reply(%Reply{}))} end)
    |> Map.new()
  end

  defp get_user_id(session, socket) do
    # Try to get from session first
    case session["user_id"] do
      nil ->
        # Generate from IP if no session ID
        ip = socket.assigns.client_ip || "127.0.0.1"
        ip_string = :inet.ntoa(ip) |> to_string()
        "ip_#{ip_string}"
      user_id ->
        user_id
    end
  end

  @impl true
  def handle_event("filter-community", %{"community_id" => "home"}, socket) do
    posts = Temporal.list_active_posts(limit: @posts_per_page)

    {:noreply,
     socket
     |> assign(:community, nil)
     |> stream(:posts, posts, reset: true)
     |> assign(:page, 1)
     |> assign(:has_more, length(posts) == @posts_per_page)}
  end

  @impl true
  def handle_event("filter-community", %{"community_id" => community_id}, socket) do
    community = Arblarg.Communities.get_community_by_id!(community_id)
    posts = Temporal.list_active_posts(community_id: community.id, limit: @posts_per_page)

    {:noreply,
     socket
     |> assign(:community, community)
     |> stream(:posts, posts, reset: true)
     |> assign(:page, 1)
     |> assign(:has_more, length(posts) == @posts_per_page)}
  end

  # Add this helper function for error messages
  defp error_to_string({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      # Unsubscribe from old topic if it exists
      if old_topic = socket.assigns[:current_shoutbox_topic] do
        Phoenix.PubSub.unsubscribe(Arblarg.PubSub, old_topic)
      end

      # Get community_id from params, will be nil for global feed
      community_id = params["community_id"]

      # Subscribe to new topic
      new_topic = Temporal.shoutbox_topic(community_id)
      Phoenix.PubSub.subscribe(Arblarg.PubSub, new_topic)

      socket = assign(socket, :current_shoutbox_topic, new_topic)
    end

    {:noreply, socket}
  end
end
