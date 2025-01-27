defmodule ArblargWeb.FaqLive do
  use ArblargWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "FAQ")}
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

        <div class="space-y-2">
          <h2 class="text-lg font-semibold text-white">How does the trending posts section work?</h2>
          <div class="text-zinc-300 leading-relaxed space-y-4">
            <p>
              The trending section shows posts that are currently generating the most discussion. Posts are ranked using a combination of factors:
            </p>

            <ul class="space-y-2 list-disc pl-5">
              <li>
                <span class="text-white">Total replies</span> - The more replies a post has, the higher it ranks
              </li>
              <li>
                <span class="text-white">Recent activity</span> - Posts with replies in the last 3 hours get a significant boost
              </li>
              <li>
                <span class="text-white">Freshness</span> - Newer posts rank higher than older ones with similar engagement
              </li>
            </ul>

            <p class="text-sm text-zinc-400">
              For example, a new post with 5 recent replies might rank higher than an older post with 10 total replies but no recent activity. This helps surface active discussions while letting older conversations naturally fade away.
            </p>

            <p class="text-sm text-zinc-400">
              Only posts from the last 24 hours are considered for trending, and the list updates automatically as new replies come in.
            </p>
          </div>
        </div>
      </div>

      <div class="pt-8 border-t border-zinc-800">
        <p class="text-zinc-300">
          Have more questions? Check out our <.link navigate="/about" class="text-red-400 hover:text-red-300">About page</.link>
          or view the <.link href="https://github.com/businessfunk/arblarg" class="text-red-400 hover:text-red-300">source code</.link>.
        </p>
      </div>
    </div>
    """
  end
end
