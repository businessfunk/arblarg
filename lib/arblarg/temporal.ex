defmodule Arblarg.Temporal do
  @moduledoc """
  Context module for ephemeral posts and replies.
  Includes momentum-based expiration: each new reply extends post life
  slightly, up to a maximum of 7 days from creation.
  """

  import Ecto.Query, warn: false
  alias Arblarg.Repo
  alias Arblarg.Temporal.Post
  alias Arblarg.Temporal.Reply
  alias Arblarg.RateLimiter
  alias Arblarg.Temporal.Shout
  alias Arblarg.Temporal.PostInteraction
  require Logger

  @posts_cache :posts_cache

  # How many seconds to extend on each reply:
  @reply_momentum_seconds 1800    # 30 minutes
  # Maximum total lifespan in hours from post's inserted_at:
  @max_post_lifespan_hours 168    # 7 days

  @shoutbox_topic "shoutbox:messages"

  def start_cache do
    case :ets.whereis(@posts_cache) do
      :undefined ->
        :ets.new(@posts_cache, [:set, :public, :named_table])
      _ ->
        :ok
    end
  end

  def list_active_posts(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)
    community_id = Keyword.get(opts, :community_id)

    Post
    |> where([p], p.expires_at > ^DateTime.utc_now())
    |> filter_by_community(community_id)
    |> order_by([p], desc: p.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> preload([:community, :replies])
    |> Repo.all()
  end

  defp filter_by_community(query, nil), do: query
  defp filter_by_community(query, community_id) do
    where(query, [p], p.community_id == ^community_id)
  end

  defp cache_valid?(timestamp) do
    DateTime.diff(DateTime.utc_now(), timestamp, :second) < 30 # 30 second cache
  end

  @doc """
  Searches through active posts based on a query string.
  Matches against post body and author fields.
  """
  def search_posts(query) do
    search_term = "%#{query}%"

    Post
    |> where([p], p.expires_at > ^DateTime.utc_now())
    |> where([p], ilike(p.body, ^search_term) or ilike(p.author, ^search_term))
    |> order_by([p], desc: p.inserted_at)
    |> limit(20)
    |> preload([:replies, :community])
    |> Repo.all()
  end

  defp fetch_and_cache_posts(limit, offset, cache_key) do
    posts =
      Post
      |> where([p], p.expires_at > ^DateTime.utc_now())
      |> order_by([p], desc: p.inserted_at)
      |> limit(^limit)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload(replies: from(r in Reply, order_by: [asc: r.inserted_at]))

    :ets.insert(@posts_cache, {cache_key, posts, DateTime.utc_now()})
    posts
  end

  def create_post(attrs, user_id) do
    case RateLimiter.check_post_rate(user_id) do
      :ok ->
        %Post{}
        |> Post.changeset(attrs)
        |> Repo.insert()
        |> case do
          {:ok, post} ->
            post = Repo.preload(post, [:replies, :community])
            broadcast({:post_created, post})
          error ->
            error
        end

      {:error, :rate_limit} ->
        {:error, :rate_limit}
    end
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Arblarg.PubSub, "posts")
  end

  @doc """
  Broadcasts a post-related event to all subscribers.
  """
  def broadcast({:post_created, post}) do
    Phoenix.PubSub.broadcast(Arblarg.PubSub, "posts", {:post_created, post})
    {:ok, post}
  end

  def broadcast({:post_expired, post_id}) do
    Phoenix.PubSub.broadcast(Arblarg.PubSub, "posts", {:post_expired, post_id})
    # Invalidate cache
    :ets.match_delete(@posts_cache, {:"$1", :_, :_})
    {:ok, post_id}
  end

  def broadcast({:post_updated, post}) do
    Phoenix.PubSub.broadcast(Arblarg.PubSub, "posts", {:post_updated, post})
    {:ok, post}
  end

  defp broadcast_post({:ok, post}) do
    broadcast({:post_created, post})

    # Invalidate cache
    :ets.match_delete(@posts_cache, {:"$1", :_, :_})

    # Schedule expiration broadcast
    expiration_ms = DateTime.diff(post.expires_at, DateTime.utc_now(), :millisecond)
    if expiration_ms > 0 do
      Process.send_after(self(), {:expire_post, post.id}, expiration_ms)
    end

    {:ok, post}
  end

  defp broadcast_post(error), do: error

  # Reschedule the post's expiration broadcast when extending its expires_at.
  defp broadcast_update(%Post{} = post) do
    post = Repo.preload(post, [:replies, :community])
    broadcast({:post_updated, post})

    # Invalidate cache
    :ets.match_delete(@posts_cache, {:"$1", :_, :_})

    # Schedule new expiration broadcast
    expiration_ms = DateTime.diff(post.expires_at, DateTime.utc_now(), :millisecond)
    if expiration_ms > 0 do
      Process.send_after(self(), {:expire_post, post.id}, expiration_ms)
    end

    {:ok, post}
  end

  # Momentum-based extension: each reply extends the expiration
  # by @reply_momentum_seconds, capped at 7 days from inserted_at.
  defp maybe_extend_expiration(post_id) do
    with %Post{} = post <- Repo.get(Post, post_id),
         :gt <- DateTime.compare(post.expires_at, DateTime.utc_now())
    do
      # Convert NaiveDateTime to DateTime for proper comparison
      extension_target = DateTime.from_naive!(post.expires_at, "Etc/UTC") |> DateTime.add(@reply_momentum_seconds, :second)
      max_expires = DateTime.from_naive!(post.inserted_at, "Etc/UTC") |> DateTime.add(@max_post_lifespan_hours * 3600, :second)

      new_expires_at =
        if DateTime.compare(extension_target, max_expires) == :gt do
          max_expires
        else
          extension_target
        end

      if DateTime.compare(new_expires_at, DateTime.from_naive!(post.expires_at, "Etc/UTC")) == :gt do
        post
        |> Ecto.Changeset.change(expires_at: new_expires_at)
        |> Repo.update()
      else
        {:ok, post}
      end
    else
      _ -> :noop
    end
  end

  def handle_info({:expire_post, post_id}, socket) do
    # Double-check if post is truly expired now
    case get_post(post_id) do
      nil ->
        # Already expired or not found
        broadcast({:post_expired, post_id})

      %Post{} = post ->
        # Post is still active, re-schedule if needed
        expiration_ms = DateTime.diff(post.expires_at, DateTime.utc_now(), :millisecond)
        if expiration_ms > 0 do
          Process.send_after(self(), {:expire_post, post.id}, expiration_ms)
        end
    end

    {:noreply, socket}
  end

  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def create_reply(post_id, attrs, user_id) do
    case RateLimiter.check_reply_rate(user_id) do
      :ok ->
        post_id = if is_binary(post_id), do: String.to_integer(post_id), else: post_id

        %Reply{}
        |> Reply.changeset(Map.put(attrs, "post_id", post_id))
        |> Repo.insert()
        |> case do
          {:ok, reply} ->
            _ = maybe_extend_expiration(post_id)
            post = get_post!(post_id)
            broadcast_update(post)
            {:ok, reply}

          error ->
            error
        end

      {:error, :rate_limit} ->
        {:error, :rate_limit}
    end
  end

  def get_post!(id) do
    Post
    |> preload([:replies, :community])
    |> Repo.get!(id)
  end

  def change_reply(%Reply{} = reply, attrs \\ %{}) do
    Reply.changeset(reply, attrs)
  end

  def get_post(id) do
    case Repo.get(Post, id) do
      nil -> nil
      post ->
        if DateTime.compare(post.expires_at, DateTime.utc_now()) == :gt do
          Repo.preload(post, :replies)
        else
          nil
        end
    end
  end

  def list_thread_authors(post_id) do
    post = get_post!(post_id)
    [post.author | Enum.map(post.replies, & &1.author)]
    |> Enum.uniq()
  end

  @doc """
  Creates a post without rate limiting - only for stress testing.
  """
  def create_post!(attrs) do
    if Mix.env() != :dev do
      raise "create_post!/1 can only be used in development mode"
    end

    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def list_recent_shouts(community_id) do
    base_query = Shout
      |> where([s], s.expires_at > ^DateTime.utc_now())
      |> order_by([s], [asc: s.inserted_at])
      |> limit(1000)

    query = if is_nil(community_id) do
      # For global shoutbox
      where(base_query, [s], is_nil(s.community_id))
    else
      # For community-specific shoutbox
      where(base_query, [s], s.community_id == ^community_id)
    end

    query
    |> Repo.all()
    |> Enum.map(fn shout ->
      # Convert timestamps to UTC DateTime
      %{shout |
        inserted_at: DateTime.from_naive!(shout.inserted_at, "Etc/UTC"),
        updated_at: DateTime.from_naive!(shout.updated_at, "Etc/UTC")
      }
    end)
  end

  def create_shout(attrs) do
    %Shout{}
    |> Shout.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, shout} ->
        # Preload the community association
        shout = Repo.preload(shout, :community)
        # Let the LiveView handle the broadcast
        {:ok, shout}
      error ->
        error
    end
  end

  def shoutbox_topic(nil), do: "shoutbox:global"
  def shoutbox_topic(community_id), do: "shoutbox:community:#{community_id}"

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
      case create_post!(params) do
        {:ok, post} ->
          post = Arblarg.Repo.preload(post, [:replies, :community])
          broadcast({:post_created, post})
        _ -> nil
      end
    end)
  end

  def list_trending_posts(opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    hours = Keyword.get(opts, :hours, 24)
    now = DateTime.utc_now()
    three_hours_ago = DateTime.add(now, -3 * 3600)

    # First, get posts with their total reply counts
    base_query = from(p in Post,
      where: p.expires_at > ^now,
      where: p.inserted_at > ago(^hours, "hour"),
      left_join: r in assoc(p, :replies),
      group_by: p.id,
      select: %{
        post_id: p.id,
        total_replies: count(r.id)
      }
    )

    # Then, get recent reply counts
    recent_replies_query = from(r in Reply,
      where: r.inserted_at > ^three_hours_ago,
      group_by: r.post_id,
      select: %{
        post_id: r.post_id,
        recent_count: count(r.id)
      }
    )

    # Combine the queries and calculate the score
    from(p in Post,
      as: :post,
      join: b in subquery(base_query), as: :base, on: b.post_id == p.id,
      left_join: rr in subquery(recent_replies_query), as: :recent, on: rr.post_id == p.id,
      select: p,
      select_merge: %{
        score: fragment(
          "? * (1.0 + (COALESCE(?, 0) * 0.5)) * pow(0.9, extract(epoch from ? - ?)::float / 3600.0)",
          b.total_replies,
          type(rr.recent_count, :integer),
          type(^now, :utc_datetime),
          p.inserted_at
        )
      },
      order_by: [
        desc: fragment(
          "? * (1.0 + (COALESCE(?, 0) * 0.5)) * pow(0.9, extract(epoch from ? - ?)::float / 3600.0)",
          b.total_replies,
          type(rr.recent_count, :integer),
          type(^now, :utc_datetime),
          p.inserted_at
        )
      ],
      preload: [:community, :replies],
      limit: ^limit
    )
    |> Repo.all()
  end

  def track_interaction(session_id, post_id) do
    require Logger
    Logger.debug("Attempting to track interaction - Session ID: #{inspect(session_id)}, Post ID: #{inspect(post_id)}")

    # Convert post_id to integer if it's a string
    post_id = if is_binary(post_id), do: String.to_integer(post_id), else: post_id

    %PostInteraction{}
    |> PostInteraction.changeset(%{session_id: session_id, post_id: post_id})
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: [:session_id, :post_id]
    )
    |> case do
      {:ok, interaction} ->
        Logger.debug("Successfully tracked interaction: #{inspect(interaction)}")
        {:ok, interaction}
      {:error, changeset} ->
        Logger.debug("Failed to track interaction: #{inspect(changeset.errors)}")
        {:error, changeset}
      # Handle the case where on_conflict: :nothing returns nil
      {:ok, nil} -> {:ok, :already_tracked}
    end
  end

  def list_user_interactions(session_id, limit \\ 50) do
    from(p in Post,
      join: pi in PostInteraction,
      on: pi.post_id == p.id,
      where: pi.session_id == ^session_id and p.expires_at > ^DateTime.utc_now(),
      order_by: [desc: pi.inserted_at],
      preload: [:community, :replies],
      limit: ^limit
    )
    |> Repo.all()
  end
end
