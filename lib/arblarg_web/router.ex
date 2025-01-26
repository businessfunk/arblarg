defmodule ArblargWeb.Router do
  use ArblargWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ArblargWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{
      "content-security-policy" => "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' https: data: *; media-src *; frame-src 'self' https://www.youtube.com https://youtube.com; connect-src 'self' ws: wss:; font-src 'self';"
    }
    plug :assign_user_identity
    plug :put_security_headers
  end

  defp assign_user_identity(conn, _opts) do
    if get_session(conn, :user_id) do
      conn
    else
      user_id = :crypto.strong_rand_bytes(32) |> Base.encode64()
      conn
      |> put_session(:user_id, user_id)
    end
  end

  defp put_security_headers(conn, _opts) do
    conn
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-xss-protection", "1; mode=block")
    |> put_resp_header("x-download-options", "noopen")
    |> put_resp_header("x-permitted-cross-domain-policies", "none")
    |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    |> put_resp_header("permissions-policy", "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()")
  end

  scope "/", ArblargWeb do
    pipe_through :browser

    live "/", PostLive.Index
    live "/c/:community_slug", PostLive.Index
    live "/c/:community_slug/posts/:id", PostLive.Show
    live "/posts/:id", PostLive.Show
    live "/search", SearchLive, :index
    live "/about", AboutLive, :index
    live "/faq", FaqLive, :index
    live "/settings", SettingsLive, :index
  end

  if Application.compile_env(:arblarg, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
