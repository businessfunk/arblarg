defmodule ArblargWeb.PostLive.Show do
  use ArblargWeb, :live_view
  alias Arblarg.{Temporal, UserIdentity}
  alias Arblarg.Temporal.Reply
  import ArblargWeb.PostComponents
  require Logger
  alias Arblarg.RateLimiter
  alias Arblarg.HtmlSanitizer

  @impl true
  def mount(%{"id" => id}, session, socket) do
    if connected?(socket), do: Temporal.subscribe()

    case Temporal.get_post!(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Post not found or expired")
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

        {:ok,
         socket
         |> assign(:page_title, "Post by #{post.author}")
         |> assign(:post, post)
         |> assign(:thread_identity, thread_identity)
         |> assign(:reply_form, to_form(Temporal.change_reply(%Reply{})))}
    end
  end

  @impl true
  def handle_event("reply", params, socket) do
    post_id = params["post-id"]
    reply_params = params["reply"]
    Logger.debug("""
    Creating reply:
    Post ID: #{post_id}
    Params: #{inspect(reply_params)}
    Thread Identity: #{inspect(socket.assigns.thread_identity)}
    Is OP: #{socket.assigns.post.author == socket.assigns.thread_identity}
    """)

    reply_params = Map.put(reply_params, "author", socket.assigns.thread_identity)
    reply_params = Map.put(reply_params, "is_op", socket.assigns.post.author == socket.assigns.thread_identity)

    case Temporal.create_reply(
      post_id,
      reply_params
    ) do
      {:ok, _reply} ->
        Logger.debug("Reply created successfully")
        {:noreply,
         socket
         |> assign(:reply_form, to_form(Temporal.change_reply(%Reply{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.debug("Reply creation failed: #{inspect(changeset.errors)}")
        {:noreply, assign(socket, :reply_form, to_form(changeset))}
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

  def handle_info(_, socket), do: {:noreply, socket}
end
