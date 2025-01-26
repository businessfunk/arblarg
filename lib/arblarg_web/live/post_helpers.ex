defmodule ArblargWeb.PostHelpers do
  @doc """
  Formats the expiration time of a post.
  """
  def format_expiration(expires_at) do
    now = DateTime.utc_now()
    diff = DateTime.diff(expires_at, now, :second)

    cond do
      diff <= 0 ->
        "Expired"
      diff < 3600 ->
        "#{div(diff, 60)}m left"
      diff < 86400 ->
        "#{div(diff, 3600)}h left"
      true ->
        "#{div(diff, 86400)}d left"
    end
  end
end
