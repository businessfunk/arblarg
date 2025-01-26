defmodule ArblargWeb.InitAssigns do
  @moduledoc """
  Ensures common `assigns` are applied to all LiveViews attaching this hook.
  """
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    socket = assign_new(socket, :current_path, fn ->
      case socket.view do
        ArblargWeb.PostLive.Index -> "/"
        ArblargWeb.SearchLive -> "/search"
        ArblargWeb.FaqLive -> "/faq"
        ArblargWeb.AboutLive -> "/about"
        ArblargWeb.SettingsLive -> "/settings"
        _ -> "/"
      end
    end)

    {:cont, socket}
  end
end
