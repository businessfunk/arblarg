defmodule ArblargWeb.AboutLive do
  use ArblargWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div class="space-y-4">
        <h1 class="text-2xl font-bold text-white">About Arblarg</h1>
        <p class="text-zinc-300 leading-relaxed">
          Arblarg is a minimalist social platform for ephemeral conversations. Posts naturally fade away after their expiration time, creating a space for authentic, in-the-moment discussions without the pressure of permanent social media.
        </p>
      </div>

      <div class="space-y-6">
        <div class="space-y-2">
          <h2 class="text-lg font-semibold text-white">How it works</h2>
          <ul class="space-y-3 text-zinc-300">
            <li class="flex items-start gap-2">
              <span class="text-red-400">→</span>
              Share your thoughts, links, and media in global feed or communities
            </li>
            <li class="flex items-start gap-2">
              <span class="text-red-400">→</span>
              Choose post expiration time: 24 hours to 7 days
            </li>
            <li class="flex items-start gap-2">
              <span class="text-red-400">→</span>
              Engage in real-time discussions through replies
            </li>
            <li class="flex items-start gap-2">
              <span class="text-red-400">→</span>
              Join topic-focused communities
            </li>
            <li class="flex items-start gap-2">
              <span class="text-red-400">→</span>
              No accounts, likes, or follows - just pure conversation
            </li>
          </ul>
        </div>

        <div class="space-y-2">
          <h2 class="text-lg font-semibold text-white">Features</h2>
          <ul class="space-y-3 text-zinc-300">
            <li class="flex items-start gap-2">
              <span class="text-red-400">•</span>
              Rich media support: YouTube embeds and link previews
            </li>
            <li class="flex items-start gap-2">
              <span class="text-red-400">•</span>
              Real-time updates and notifications
            </li>
            <li class="flex items-start gap-2">
              <span class="text-red-400">•</span>
              Community-specific discussions
            </li>
            <li class="flex items-start gap-2">
              <span class="text-red-400">•</span>
              Shoutbox for quick community chat
            </li>
            <li class="flex items-start gap-2">
              <span class="text-red-400">•</span>
              Media toggle for bandwidth control
            </li>
          </ul>
        </div>

        <div class="space-y-2">
          <h2 class="text-lg font-semibold text-white">Technology</h2>
          <p class="text-zinc-300 leading-relaxed">
            Built with Elixir, Phoenix LiveView, and PostgreSQL. The entire application runs in real-time, providing instant updates and a smooth user experience with minimal JavaScript.
          </p>
          <div class="flex gap-4 mt-4">
            <.link href="https://github.com/businessfunk/arblarg" class="text-red-400 hover:text-red-300">
              View source code →
            </.link>
            <.link href="https://elixir-lang.org" class="text-red-400 hover:text-red-300">
              Learn about Elixir →
            </.link>
          </div>
        </div>
      </div>

      <div class="pt-8 border-t border-zinc-800">
        <p class="text-zinc-500 text-sm">
          Created by <a href="https://github.com/businessfunk" class="text-zinc-400 hover:text-white transition-colors">@businessfunk</a>
        </p>
      </div>
    </div>
    """
  end
end
