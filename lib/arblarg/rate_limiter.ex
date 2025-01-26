defmodule Arblarg.RateLimiter do
  @moduledoc """
  Rate limiting functionality using Hammer.
  """

  # 5 posts per minute per user
  @post_limit_scale 60_000
  @post_limit_count 5

  # 10 replies per minute per user
  @reply_limit_scale 60_000
  @reply_limit_count 10

  def check_post_rate(user_id) do
    case Hammer.check_rate("post:#{user_id}", @post_limit_scale, @post_limit_count) do
      {:allow, _count} -> :ok
      {:deny, _limit} -> {:error, :rate_limit}
    end
  end

  def check_reply_rate(user_id) do
    case Hammer.check_rate("reply:#{user_id}", @reply_limit_scale, @reply_limit_count) do
      {:allow, _count} -> :ok
      {:deny, _limit} -> {:error, :rate_limit}
    end
  end
end
