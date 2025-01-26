const Shoutbox = {
  mounted() {
    this.scrollToBottom()
    
    this.handleEvent("scroll-shoutbox", () => {
      this.scrollToBottom()
    })

    // Add mutation observer to handle dynamic content
    this.observer = new MutationObserver(() => {
      this.scrollToBottom()
      this.updateAllTimestamps() // Update timestamps when content changes
    })

    const messages = this.el.querySelector('.shoutbox-messages')
    if (messages) {
      this.observer.observe(messages, {
        childList: true,
        subtree: true
      })
    }

    // Update timestamps every minute
    this.timestampInterval = setInterval(() => {
      this.updateAllTimestamps()
    }, 60000) // Every minute

    // Initial timestamp update
    this.updateAllTimestamps()
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.timestampInterval) {
      clearInterval(this.timestampInterval)
    }
  },

  scrollToBottom() {
    const messages = this.el.querySelector('.shoutbox-messages')
    if (messages) {
      requestAnimationFrame(() => {
        messages.scrollTop = messages.scrollHeight
      })
    }
  },

  updateAllTimestamps() {
    const timestamps = this.el.querySelectorAll('[data-timestamp]')
    timestamps.forEach(ts => {
      const datetime = ts.getAttribute('datetime')
      if (datetime) {
        ts.textContent = this.formatRelativeTime(new Date(datetime))
      }
    })
  },

  formatRelativeTime(date) {
    const now = new Date()
    const diffInSeconds = Math.floor((now - date) / 1000)
    
    if (diffInSeconds < 60) {
      return 'just now'
    } else if (diffInSeconds < 3600) {
      const minutes = Math.floor(diffInSeconds / 60)
      return `${minutes}m ago`
    } else if (diffInSeconds < 86400) {
      const hours = Math.floor(diffInSeconds / 3600)
      return `${hours}h ago`
    } else {
      const days = Math.floor(diffInSeconds / 86400)
      return `${days}d ago`
    }
  }
}

export default Shoutbox 