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
          Arblarg is a minimalist social platform for ephemeral thoughts. Every post disappears after 24 hours,
          creating a space for authentic, in-the-moment sharing without the burden of permanence.
        </p>
      </div>

      <div class="space-y-4">
        <h2 class="text-xl font-semibold text-white">How it works</h2>
        <ul class="space-y-3 text-zinc-300">
          <li class="flex gap-2 items-start">
            <span class="text-red-400 font-mono">→</span>
            <span>Share your thoughts, links, or ideas</span>
          </li>
          <li class="flex gap-2 items-start">
            <span class="text-red-400 font-mono">→</span>
            <span>Posts automatically expire after 24 hours</span>
          </li>
          <li class="flex gap-2 items-start">
            <span class="text-red-400 font-mono">→</span>
            <span>Engage in discussions through replies</span>
          </li>
          <li class="flex gap-2 items-start">
            <span class="text-red-400 font-mono">→</span>
            <span>No likes, no follows - just pure conversation</span>
          </li>
        </ul>
      </div>

      <div class="space-y-4">
        <h2 class="text-xl font-semibold text-white">Technology</h2>
        <p class="text-zinc-300 leading-relaxed">
          Built with Elixir, Phoenix LiveView, and PostgreSQL. The entire application runs in real-time,
          providing instant updates and a smooth user experience.
        </p>
        <div class="flex gap-4 text-sm">
          <a href="https://github.com/alphafield/arblarg"
             class="text-red-400 hover:text-red-300 transition-colors">
            View source code →
          </a>
          <a href="https://elixir-lang.org"
             class="text-red-400 hover:text-red-300 transition-colors">
            Learn about Elixir →
          </a>
        </div>
      </div>

      <div class="pt-8 border-t border-zinc-800">
        <p class="text-zinc-500 text-sm">
          Created by <a href="https://github.com/alphafield" class="text-zinc-400 hover:text-white transition-colors">@alphafield</a>
        </p>
      </div>
    </div>
    """
  end
end
