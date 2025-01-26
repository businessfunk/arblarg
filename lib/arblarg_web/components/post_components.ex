defmodule ArblargWeb.PostComponents do
  use Phoenix.Component
  import ArblargWeb.CoreComponents
  import Phoenix.Component

  def post_header(assigns) do
    ~H"""
    <div class="flex justify-between items-start gap-2">
      <div class="flex items-center gap-2">
        <div class="w-8 h-8 rounded-full bg-red-900 flex items-center justify-center">
          <span class="text-sm text-red-200 font-medium"><%= String.first(@author) %></span>
        </div>
        <div>
          <span class="text-sm font-medium text-white"><%= @author %></span>
          <span class="text-xs text-zinc-500 ml-2">No.<%= @id %></span>
          <div class="text-xs text-gray-400" data-timestamp>
            <%= Timex.format!(@inserted_at, "{relative}", :relative) %>
          </div>
        </div>
      </div>
      <div class="text-xs text-gray-500" data-timestamp>
        <%= ArblargWeb.PostHelpers.format_expiration(@expires_at) %>
      </div>
    </div>
    """
  end

  def link_preview(assigns) do
    ~H"""
    <a :if={@link} href={@link} target="_blank" rel="noopener noreferrer"
       class="mt-3 block border border-zinc-800 rounded-lg overflow-hidden hover:bg-zinc-800 transition-colors">
      <img :if={@link_image} src={@link_image} alt="" class="w-full h-48 object-cover"/>
      <div class="p-3">
        <div class="text-xs text-gray-400 truncate"><%= @link_domain %></div>
        <div :if={@link_title} class="font-medium text-white truncate"><%= @link_title %></div>
        <div :if={@link_description} class="text-sm text-gray-400 line-clamp-2 mt-1"><%= @link_description %></div>
      </div>
    </a>
    """
  end

  def reply_list(assigns) do
    ~H"""
    <div :if={Enum.any?(@replies)} class="border-t border-zinc-800 pt-4 space-y-4 mb-6">
      <div :for={reply <- @replies} class="group flex items-start gap-2">
        <div class="w-6 h-6 rounded-full bg-zinc-800 flex-shrink-0 flex items-center justify-center">
          <span class="text-xs text-gray-300"><%= String.first(reply.author) %></span>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-baseline gap-2">
            <span class="text-sm font-medium text-white"><%= reply.author %></span>
            <span :if={reply.is_op} class="text-xs bg-red-900/50 text-red-200 px-1.5 py-0.5 rounded">OP</span>
            <span class="text-xs text-zinc-500">No.<%= reply.id %></span>
            <span class="text-xs text-gray-500" data-timestamp>
              <%= Timex.format!(reply.inserted_at, "{relative}", :relative) %>
            </span>
          </div>
          <p class="text-sm text-gray-300"><%= reply.body %></p>
        </div>
      </div>
    </div>
    """
  end

  def reply_form(assigns) do
    ~H"""
    <.form for={@form} phx-submit="reply" phx-value-post-id={@post_id} class="mt-6 pt-4 border-t border-zinc-800">
      <div class="space-y-2">
        <div class="flex items-center gap-2">
          <div class="flex-1">
            <.input field={@form[:body]} type="text"
                    placeholder="Reply to this blarg..."
                    class="bg-zinc-900 text-white border-zinc-700"
                    phx-debounce="blur"/>
          </div>
          <.button phx-disable-with="..." size="xs">Respond</.button>
        </div>
        <div :if={@form.errors[:body]} class="text-sm text-red-400 mt-1">
          <%= error_to_string(@form.errors[:body]) %>
        </div>
      </div>
    </.form>
    """
  end

  defp error_to_string({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end
end
