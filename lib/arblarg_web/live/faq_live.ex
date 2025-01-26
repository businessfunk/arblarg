defmodule ArblargWeb.FaqLive do
  use ArblargWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div class="space-y-4">
        <h1 class="text-2xl font-bold text-white">Frequently Asked Questions</h1>
        <p class="text-zinc-300">
          Common questions and answers about using Arblarg.
        </p>
      </div>

      <div class="space-y-6">
        <div class="space-y-2">
          <h2 class="text-lg font-semibold text-white">Why do posts disappear?</h2>
          <p class="text-zinc-300 leading-relaxed">
            Posts are designed to be ephemeral to encourage authentic, in-the-moment sharing.
            You can choose how long your posts stay visible, from 24 hours up to 7 days.
            Like a real conversation, they naturally fade away after the chosen time. This helps keep
            discussions fresh and reduces the anxiety of permanent social media posts.
          </p>
        </div>

        <div class="space-y-2">
          <h2 class="text-lg font-semibold text-white">Can I delete my posts manually?</h2>
          <p class="text-zinc-300 leading-relaxed">
            Yes, you can delete your own posts at any time before they automatically expire.
            However, remember that others might have already seen or replied to them.
          </p>
        </div>

        <div class="space-y-2">
          <h2 class="text-lg font-semibold text-white">What happens to replies when a post expires?</h2>
          <p class="text-zinc-300 leading-relaxed">
            When a post expires, all of its replies are also removed. This keeps the conversation
            context intact and ensures that discussions remain timely.
          </p>
        </div>

        <div class="space-y-2">
          <h2 class="text-lg font-semibold text-white">Can I save or bookmark posts?</h2>
          <p class="text-zinc-300 leading-relaxed">
            No, Arblarg intentionally doesn't have saving or bookmarking features. The goal is to
            focus on present conversations rather than building a permanent archive.
          </p>
        </div>

        <div class="space-y-2">
          <h2 class="text-lg font-semibold text-white">Is there a mobile app?</h2>
          <p class="text-zinc-300 leading-relaxed">
            Arblarg is a web app built with responsive design, so it works great on both desktop and
            mobile browsers. There's no separate mobile app needed - just visit the website on any device.
          </p>
        </div>
      </div>

      <div class="pt-8 border-t border-zinc-800">
        <p class="text-zinc-300">
          Have more questions? Check out our <.link navigate="/about" class="text-red-400 hover:text-red-300">About page</.link>
          or view the <.link href="https://github.com/alphafield/arblarg" class="text-red-400 hover:text-red-300">source code</.link>.
        </p>
      </div>
    </div>
    """
  end
end
