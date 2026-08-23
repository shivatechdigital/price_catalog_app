const tabs = document.querySelectorAll('[data-policy]');
const panels = document.querySelectorAll('[data-panel]');
const year = document.querySelector('#year');

tabs.forEach((tab) => {
  tab.addEventListener('click', () => {
    const target = tab.dataset.policy;

    tabs.forEach((item) => {
      const selected = item === tab;
      item.classList.toggle('active', selected);
      item.setAttribute('aria-selected', String(selected));
    });

    panels.forEach((panel) => {
      panel.classList.toggle('hidden', panel.id !== target);
    });

    window.history.replaceState(null, '', `#${target}`);
  });
});

const initialPolicy = window.location.hash.replace('#', '');
if (initialPolicy === 'terms') {
  document.querySelector('[data-policy="terms"]').click();
}

year.textContent = new Date().getFullYear();
