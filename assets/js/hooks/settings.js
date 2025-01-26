const Settings = {
  mounted() {
    // Load saved setting on mount
    const setting = this.el.dataset.setting
    const savedValue = localStorage.getItem(`arblarg:${setting}`)
    
    // Handle initial state - if checked attribute exists, use it as default
    if (savedValue === null && this.el.hasAttribute('checked')) {
      localStorage.setItem(`arblarg:${setting}`, 'true')
      document.documentElement.setAttribute(`data-${setting}`, 'true')
      this.el.checked = true
    } else if (savedValue === 'true') {
      this.el.checked = true
      document.documentElement.setAttribute(`data-${setting}`, 'true')
    } else {
      // Set explicit false state on load if not true
      this.el.checked = false
      document.documentElement.setAttribute(`data-${setting}`, 'false')
    }

    // Save setting on change
    this.el.addEventListener('change', (e) => {
      const setting = this.el.dataset.setting
      const value = e.target.checked
      localStorage.setItem(`arblarg:${setting}`, value)
      document.documentElement.setAttribute(`data-${setting}`, value)
    })
  }
}

export default Settings 