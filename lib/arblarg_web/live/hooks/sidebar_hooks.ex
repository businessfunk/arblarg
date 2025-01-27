defmodule ArblargWeb.Live.Hooks.SidebarHooks do
  import Phoenix.Component
  alias Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:community_search, "")
     |> assign(:searched_communities, [])}
  end
end
