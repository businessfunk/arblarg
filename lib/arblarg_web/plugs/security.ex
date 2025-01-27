defmodule ArblargWeb.Plugs.Security do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> validate_ip
    |> validate_user_agent
    |> protect_from_abuse
  end

  defp validate_ip(conn) do
    client_ip = get_client_ip(conn)

    if is_blocked_ip?(client_ip) do
      conn
      |> put_status(:forbidden)
      |> put_view(ArblargWeb.ErrorView)
      |> render("403.html")
      |> halt()
    else
      conn
    end
  end

  defp validate_user_agent(conn) do
    user_agent = get_req_header(conn, "user-agent") |> List.first()

    if is_suspicious_user_agent?(user_agent) do
      conn
      |> put_status(:forbidden)
      |> halt()
    else
      conn
    end
  end

  defp protect_from_abuse(conn) do
    # Add connection to global rate limiter
    case Hammer.check_rate(
      "global:#{get_client_ip(conn)}",
      60_000,  # 1 minute
      100      # 100 requests per minute
    ) do
      {:allow, _count} -> conn
      {:deny, _count} ->
        conn
        |> put_status(:too_many_requests)
        |> halt()
    end
  end

  defp get_client_ip(conn) do
    conn
    |> get_req_header("x-forwarded-for")
    |> List.first()
    |> case do
      nil -> to_string(:inet_parse.ntoa(conn.remote_ip))
      ip -> String.split(ip, ",") |> List.first()
    end
  end

  defp is_blocked_ip?(ip) do
    # Implement IP blocking logic (e.g., check against a blocklist)
    false
  end

  defp is_suspicious_user_agent?(nil), do: true
  defp is_suspicious_user_agent?(ua) do
    String.match?(ua, ~r/^(curl|wget|python|java|perl|ruby|go|rust)/i) or
    String.length(ua) < 10
  end
end
