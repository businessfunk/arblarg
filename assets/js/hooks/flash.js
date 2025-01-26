const Flash = {
  mounted() {
    // Get the progress bar element
    const progressBar = this.el.querySelector('.flash-progress');
    
    // Start the progress animation
    if (progressBar) {
      progressBar.style.transition = 'width 5000ms linear';
      // Use requestAnimationFrame to ensure the initial 100% width is set
      requestAnimationFrame(() => {
        progressBar.style.width = '0%';
      });
    }

    // Set timer for removing the flash
    this.timer = setTimeout(() => {
      this.pushEventTo(this.el, "lv:clear-flash", {
        key: this.el.getAttribute("phx-value-key")
      });
      this.el.classList.remove("opacity-100");
      this.el.classList.add("opacity-0");
      setTimeout(() => this.el.remove(), 500);
    }, 5000);
  },
  destroyed() {
    clearTimeout(this.timer);
  }
};

export default Flash; 