defmodule ArblargWeb.ShoutboxLive do
  use ArblargWeb, :live_component
  alias Arblarg.Temporal
  alias Arblarg.Temporal.Shout
  alias Phoenix.PubSub
  alias Arblarg.UserIdentity
  alias Phoenix.HTML.Format
  alias Arblarg.HtmlSanitizer

  @shoutbox_topic "shoutbox:messages"

  def update(%{new_shout: shout}, socket) do
    # Check if the shout is already in the list
    if Enum.any?(socket.assigns.shouts, fn existing -> existing.id == shout.id end) do
      {:ok, socket}
    else
      # Convert NaiveDateTime to DateTime if needed
      shout = %{shout |
        inserted_at: convert_to_datetime(shout.inserted_at),
        updated_at: convert_to_datetime(shout.updated_at)
      }

      shouts = (socket.assigns.shouts ++ [shout]) |> Enum.take(-1000)

      {:ok,
       socket
       |> assign(:shouts, shouts)
       |> push_event("scroll-shoutbox", %{})}
    end
  end

  def update(%{id: _id} = assigns, socket) do
    community_id = Map.get(assigns, :community_id)
    topic = Temporal.shoutbox_topic(community_id)

    if connected?(socket) do
      if Map.has_key?(socket.assigns, :current_topic) do
        Phoenix.PubSub.unsubscribe(Arblarg.PubSub, socket.assigns.current_topic)
      end
      Phoenix.PubSub.subscribe(Arblarg.PubSub, topic)
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:current_topic, topic)
     |> assign(:shouts, list_recent_shouts(community_id))
     |> assign(:form, to_form(%{"message" => ""}))}
  end

  def update(%{scroll: true}, socket) do
    {:ok, push_event(socket, "scroll-shoutbox", %{})}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-zinc-900 rounded-lg border border-zinc-800 shadow-lg"
         id={"shoutbox-#{@id}"}
         phx-hook="Shoutbox">
      <div class="p-3 border-b border-zinc-800 flex items-center justify-between">
        <h3 class="text-sm font-medium text-white">Shoutbox</h3>
        <span class="text-xs text-zinc-500"><%= length(@shouts) %> messages</span>
      </div>

      <div class="bg-zinc-900 rounded-lg border border-zinc-800 overflow-hidden">
        <div class="p-3 h-[300px] overflow-y-auto flex flex-col-reverse" id={"shoutbox-messages-#{@id}"}>
          <div class="space-y-2">
            <%= for shout <- @shouts do %>
              <div class="flex items-start gap-2">
                <div class="w-6 h-6 rounded-full bg-zinc-800 flex-shrink-0 flex items-center justify-center">
                  <span class="text-xs text-gray-300"><%= String.first(shout.author) %></span>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-baseline gap-2">
                    <span class="text-sm font-medium text-white"><%= shout.author %></span>
                    <span class="text-xs text-gray-500" data-timestamp datetime={DateTime.to_iso8601(shout.inserted_at)}>
                      <%= format_relative_time(shout.inserted_at) %>
                    </span>
                  </div>
                  <p class="text-sm text-gray-300 break-words"><%= shout.message %></p>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <div class="p-3 border-t border-zinc-800">
        <.form for={@form} phx-submit="shout" phx-target={@myself}>
          <div class="space-y-2">
            <.input
              field={@form[:message]}
              type="text"
              placeholder="Type a message..."
              class="bg-zinc-800 text-white border-zinc-700"
              autocomplete="off"
              maxlength="255"
              phx-change="validate"
              phx-target={@myself}
            />
            <%= if String.length((@form[:message].value || "")) > 0 do %>
              <div class="text-xs text-zinc-500 mt-1 text-right">
                <%= String.length(String.trim(@form[:message].value)) %>/255
              </div>
            <% end %>
          </div>
          <%= if flash = Phoenix.Flash.get(@flash, :error) do %>
            <div class="mt-1 text-sm text-red-400">
              <%= flash %>
            </div>
          <% end %>
        </.form>
      </div>
    </div>
    """
  end

  def handle_event("shout", %{"message" => message}, socket) do
    trimmed_message = String.trim(message)
    cond do
      trimmed_message == "" ->
        {:noreply,
         socket
         |> put_flash(:error, "Message cannot be empty")
         |> assign(:form, to_form(%{"message" => ""}))}
      String.length(trimmed_message) > 255 ->
        {:noreply,
         socket
         |> put_flash(:error, "Message must be less than 255 characters")
         |> assign(:form, to_form(%{"message" => message}))}
      true ->
        case create_shout(trimmed_message, socket.assigns.user_id, socket.assigns.community_id) do
          {:ok, shout} ->
            broadcast_shout(shout, socket.assigns.current_topic)

            {:noreply,
             socket
             |> clear_flash()
             |> assign(:form, to_form(%{"message" => ""}))}
          {:error, %Ecto.Changeset{} = changeset} ->
            error_message = case changeset.errors do
              [{:message, {"is too long", _}}] -> "Message must be less than 255 characters"
              _ -> "Error creating shout"
            end
            {:noreply,
             socket
             |> put_flash(:error, error_message)
             |> assign(:form, to_form(%{"message" => message}))}
          {:error, %Postgrex.Error{postgres: %{code: :string_data_right_truncation}}} ->
            {:noreply,
             socket
             |> put_flash(:error, "Message must be less than 255 characters")
             |> assign(:form, to_form(%{"message" => message}))}
        end
    end
  end

  def handle_event("shout", _, socket), do: {:noreply, socket}

  def handle_event("validate", %{"message" => message}, socket) do
    trimmed_length = String.length(String.trim(message))
    if trimmed_length > 255 do
      {:noreply,
       socket
       |> put_flash(:error, "Message must be less than 255 characters")
       |> assign(:form, to_form(%{"message" => message}))}
    else
      {:noreply,
       socket
       |> clear_flash()
       |> assign(:form, to_form(%{"message" => message}))}
    end
  end

  defp list_recent_shouts(community_id) do
    Temporal.list_recent_shouts(community_id)
  end

  defp create_shout(message, user_id, community_id) do
    # Generate a consistent salt for this user
    salt = generate_user_salt(user_id)
    {author, _} = UserIdentity.generate_tripcode(user_id, salt)

    attrs = %{
      "message" => message,
      "author" => author,
      "author_salt" => salt,
      "community_id" => community_id,
      "expires_at" => DateTime.utc_now() |> DateTime.add(24, :hour)
    }

    Temporal.create_shout(attrs)
  end

  defp generate_user_salt(user_id) do
    # Create a consistent salt based on the user_id
    :crypto.hash(:sha256, user_id)
    |> Base.url_encode64(padding: false)
    |> String.slice(0, 16)  # Keep a consistent length
  end

  defp get_community_name(community_id) do
    Arblarg.Communities.get_community_by_id!(community_id).name
  end

  defp error_to_string({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  def mount(socket) do
    {:ok,
     socket
     |> assign(:form, to_form(%{"message" => ""}))}
  end

  def broadcast_shout(shout, topic) do
    Phoenix.PubSub.broadcast(
      Arblarg.PubSub,
      topic,
      {:shout_created, shout}
    )
  end

  defp convert_to_datetime(%DateTime{} = dt), do: dt
  defp convert_to_datetime(%NaiveDateTime{} = ndt) do
    DateTime.from_naive!(ndt, "Etc/UTC")
  end

  defp format_relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end
end
