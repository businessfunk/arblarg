defmodule ArblargWeb.SettingsLive do
  use ArblargWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Settings")}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div class="space-y-4">
        <h1 class="text-2xl font-bold text-white">Settings</h1>
        <p class="text-zinc-300 leading-relaxed">
          Customize your Arblarg experience. Settings are saved locally in your browser.
        </p>
      </div>

      <div class="space-y-6">
        <div class="space-y-4">
          <h2 class="text-xl font-semibold text-white">Display</h2>
          <div class="space-y-4">
            <div class="flex items-center gap-4">
              <label class="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  id="setting-show-timestamps"
                  class="sr-only peer"
                  phx-hook="SaveSetting"
                  data-setting="show_timestamps"
                />
                <div class="w-11 h-6 bg-zinc-700 peer-focus:outline-none rounded-full peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-zinc-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-red-500">
                </div>
                <span class="ms-3 text-sm font-medium text-zinc-300">Show timestamps</span>
              </label>
            </div>

            <div class="flex items-center gap-4">
              <label class="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  id="setting-show-compose"
                  class="sr-only peer"
                  phx-hook="SaveSetting"
                  data-setting="show_compose"
                  checked
                />
                <div class="w-11 h-6 bg-zinc-700 peer-focus:outline-none rounded-full peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-zinc-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-red-500">
                </div>
                <span class="ms-3 text-sm font-medium text-zinc-300">Show compose form</span>
              </label>
            </div>

            <div class="flex items-center gap-4">
              <label class="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  id="setting-show-media"
                  class="sr-only peer"
                  phx-hook="SaveSetting"
                  data-setting="show_media"
                  checked
                />
                <div class="w-11 h-6 bg-zinc-700 peer-focus:outline-none rounded-full peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-zinc-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-red-500">
                </div>
                <span class="ms-3 text-sm font-medium text-zinc-300">Show media previews</span>
              </label>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
