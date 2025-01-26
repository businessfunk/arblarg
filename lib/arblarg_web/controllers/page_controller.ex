defmodule ArblargWeb.PageController do
  use ArblargWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> assign(:current_path, "/")
    |> render(:home, layout: false)
  end

  def redirect_to_general(conn, _params) do
    redirect(conn, to: ~p"/c/general")
  end
end
