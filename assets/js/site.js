document.documentElement.classList.add('js');
(() => {
  const form = document.querySelector('#research-filters');
  if (form) {
    const search = document.querySelector('#paper-search');
    const topic = document.querySelector('#topic-filter');
    const year = document.querySelector('#year-filter');
    const role = document.querySelector('#role-filter');
    const initialRole = new URLSearchParams(location.search).get('role');
    if (['lead', 'corresponding', 'preprint'].includes(initialRole)) role.value = initialRole;
    const cards = [...document.querySelectorAll('[data-work]')];
    const update = () => {
      const query = search.value.trim().toLocaleLowerCase();
      let count = 0;
      cards.forEach(card => {
        card.hidden = !!((query && !card.dataset.search.includes(query)) || (topic.value && card.dataset.topic !== topic.value) || (year.value && card.dataset.year !== year.value) || (role.value === 'lead' && card.dataset.lead !== 'true') || (role.value === 'corresponding' && card.dataset.corresponding !== 'true') || (role.value === 'preprint' && card.dataset.preprint !== 'true'));
        if (!card.hidden) count++;
      });
      document.querySelectorAll('[data-year-group]').forEach(group => { group.hidden = !group.querySelector('[data-work]:not([hidden])'); });
      document.querySelector('#result-count').textContent = count;
      document.querySelector('#no-results').hidden = count !== 0;
      document.querySelectorAll('[data-year-filter]').forEach(link => link.classList.toggle('active', link.dataset.yearFilter === year.value));
    };
    document.querySelectorAll('[data-role-filter]').forEach(link => link.addEventListener('click', event => { event.preventDefault(); role.value = link.dataset.roleFilter; update(); form.scrollIntoView({block:'start'}); }));
    update();
    form.addEventListener('submit', event => event.preventDefault());
    form.addEventListener('input', update);
    form.addEventListener('change', update);
    form.addEventListener('reset', () => { setTimeout(update, 0); });
    document.querySelectorAll('[data-year-filter]').forEach(link => link.addEventListener('click', event => {
      event.preventDefault(); year.value = year.value === link.dataset.yearFilter ? '' : link.dataset.yearFilter; update();
      document.querySelector('#research-results').scrollIntoView({block:'start'});
    }));
  }
  let timer;
  document.querySelectorAll('[data-copy]').forEach(button => button.addEventListener('click', async () => {
    const target = document.getElementById(button.dataset.copy);
    const status = document.querySelector('#copy-status');
    try {
      if (!navigator.clipboard) throw new Error('Clipboard unavailable');
      await navigator.clipboard.writeText(target.textContent.trim());
      status.textContent = document.body.dataset.copied;
    } catch {
      let ancestor = target.parentElement;
      while (ancestor) { if (ancestor.tagName === 'DETAILS') ancestor.open = true; ancestor = ancestor.parentElement; }
      const range = document.createRange(); range.selectNodeContents(target);
      const selection = window.getSelection(); selection.removeAllRanges(); selection.addRange(range);
      status.textContent = document.body.dataset.copyFail;
    }
    status.classList.add('visible'); clearTimeout(timer); timer = setTimeout(() => status.classList.remove('visible'), 3500);
  }));
  document.querySelectorAll('[data-print]').forEach(button => button.addEventListener('click', () => window.print()));
})();
