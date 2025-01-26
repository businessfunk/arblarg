const InfiniteScroll = {
  mounted() {
    const options = {
      root: null,
      rootMargin: "400px",  // Start loading before reaching the end
      threshold: 0.1
    }

    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.pushEvent("load-more")
        }
      })
    }, options)

    observer.observe(this.el)

    this.observer = observer
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}

export default InfiniteScroll 