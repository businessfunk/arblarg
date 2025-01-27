// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
// Import the settings hook
import Shoutbox from "./hooks/shoutbox"
import Flash from "./hooks/flash"
import BackToTop from "./hooks/back_to_top"

// Generate a stable user ID if one doesn't exist
let userId = localStorage.getItem('arblarg:user_id');
if (!userId) {
  userId = 'ls_' + Math.random().toString(36).substring(2, 15);
  localStorage.setItem('arblarg:user_id', userId);
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Use dynamic imports for hooks to reduce initial bundle size
const loadHooks = async () => {
  const [Settings, InfiniteScroll] = await Promise.all([
    import('./hooks/settings'),
    import('./hooks/infinite_scroll')
  ]);

  return {
    SaveSetting: Settings.default,
    InfiniteScroll: InfiniteScroll.default,
    Shoutbox: Shoutbox,
    Flash: Flash,
    BackToTop
  };
};

// Initialize LiveSocket after hooks are loaded
loadHooks().then(hooks => {
  let liveSocket = new LiveSocket("/live", Socket, {
    longPollFallbackMs: 2500,
    params: {
      _csrf_token: csrfToken,
      user_id: userId
    },
    hooks: hooks
  });

  // Show progress bar on live navigation and form submits
  topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
  window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
  window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

  // connect if there are any LiveViews on the page
  liveSocket.connect()

  // expose liveSocket on window for web console debug logs and latency simulation:
  // >> liveSocket.enableDebug()
  // >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
  // >> liveSocket.disableLatencySim()
  window.liveSocket = liveSocket

  // Apply settings on page load and navigation
  const initializeSettings = () => {
    // Initialize media setting (default to true if not set)
    const mediaValue = localStorage.getItem('arblarg:show_media');
    document.documentElement.setAttribute('data-show-media', 
      mediaValue === null ? 'true' : mediaValue);

    // Initialize other settings...
    const timestampValue = localStorage.getItem('arblarg:show_timestamps');
    document.documentElement.setAttribute('data-show-timestamps', 
      timestampValue === null ? 'true' : timestampValue);
    
    const composeValue = localStorage.getItem('arblarg:show_compose');
    document.documentElement.setAttribute('data-show-compose', 
      composeValue === null ? 'true' : composeValue);

    const backToTopButton = document.getElementById('back-to-top')
    if (!backToTopButton) return

    const toggleBackToTop = () => {
      if (window.scrollY > 500) {
        backToTopButton.classList.remove('invisible', 'opacity-0', 'translate-y-8')
      } else {
        backToTopButton.classList.add('opacity-0', 'translate-y-8')
        // Add invisible class after transition
        setTimeout(() => {
          if (window.scrollY <= 500) {
            backToTopButton.classList.add('invisible')
          }
        }, 300)
      }
    }

    window.addEventListener('scroll', () => {
      requestAnimationFrame(toggleBackToTop)
    })

    backToTopButton.addEventListener('click', () => {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      })
    })
  };

  // Initialize on page load
  document.addEventListener('DOMContentLoaded', initializeSettings);
  
  // Re-initialize on live navigation
  window.addEventListener('phx:page-loading-stop', initializeSettings);

  // Update settings when changed
  window.addEventListener('arblarg:setting-changed', (e) => {
    const { setting, value } = e.detail;
    document.documentElement.setAttribute(`data-${setting}`, String(value));
  });
})

