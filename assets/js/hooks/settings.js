const Settings = {
  mounted() {
    const setting = this.el.dataset.setting;
    const value = localStorage.getItem(`arblarg:${setting}`) !== 'false';
    this.el.checked = value;
    
    this.el.addEventListener('change', (e) => {
      const newValue = e.target.checked;
      localStorage.setItem(`arblarg:${setting}`, newValue);
      window.dispatchEvent(new CustomEvent('arblarg:setting-changed', {
        detail: { setting, value: newValue }
      }));
    });
  }
};

export default Settings; 