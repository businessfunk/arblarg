defmodule ArblargWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :arblarg

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_arblarg_key",
    signing_salt: "your_signing_salt",
    same_site: "Strict",
    secure: true,
    http_only: true,  # Prevent JavaScript access
    extra: "SameSite=Strict",
    max_age: 60 * 60 * 24 * 7  # 1 week
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [
      connect_info: [session: @session_options],
      check_origin: true,  # Prevent WebSocket CSRF
      timeout: 60_000  # 1 minute timeout
    ],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :arblarg,
    gzip: true,  # Enable gzip compression
    only: ArblargWeb.static_paths(),
    headers: [
      {"cache-control", "public, max-age=31536000"}, # 1 year for static assets
      {"x-content-type-options", "nosniff"}
    ]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :arblarg
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    length: 10_000_000,  # 10mb max upload size
    read_timeout: 60_000  # 1 minute read timeout

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug ArblargWeb.Router
end
