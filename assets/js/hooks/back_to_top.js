const BackToTop = {
  mounted() {
    this.button = document.getElementById('back-to-top')
    window.addEventListener('scroll', this.handleScroll.bind(this))
    this.button.addEventListener('click', this.scrollToTop.bind(this))
  },

  destroyed() {
    window.removeEventListener('scroll', this.handleScroll.bind(this))
    this.button.removeEventListener('click', this.scrollToTop.bind(this))
  },

  handleScroll() {
    if (window.scrollY > 500) {
      this.button.classList.remove('opacity-0', 'translate-y-8', 'invisible')
    } else {
      this.button.classList.add('opacity-0', 'translate-y-8', 'invisible')
    }
  },

  scrollToTop() {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    })
  }
}

export default BackToTop 