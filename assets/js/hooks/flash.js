const Flash = {
  mounted() {
    // Set timer for removing the flash
    this.timer = setTimeout(() => {
      this.pushEventTo(this.el, "lv:clear-flash", {
        key: this.el.getAttribute("phx-value-key")
      });
      // Add slide-out animation
      this.el.style.transform = 'translate(-50%, -100%)';
      this.el.style.opacity = '0';
      setTimeout(() => this.el.remove(), 300);
    }, 5000);
  },
  destroyed() {
    clearTimeout(this.timer);
  }
};

export default Flash; 