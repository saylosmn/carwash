(() => {
  const business = window.EASY_CONFIG?.business || {};
  const contacts = document.querySelector('#contact-links');
  const phone = String(business.phone || '').replace(/[\s()-]/g, '');
  if (/^\+?\d{8,15}$/.test(phone)) {
    const link = document.createElement('a');
    link.href = `tel:${phone}`;
    link.textContent = `Залгах · ${business.phone}`;
    contacts.append(link);
    document.querySelectorAll('[data-phone]').forEach(a => { a.href = link.href; a.hidden = false; });
  }
  for (const name of ['Facebook', 'Messenger', 'Instagram', 'WhatsApp', 'Viber']) {
    const value = business.links?.[name];
    if (!value) continue;
    try {
      const url = new URL(value);
      if (url.protocol !== 'https:' && !(name === 'Viber' && url.protocol === 'viber:')) continue;
      const a = document.createElement('a');
      a.href = url.href; a.textContent = name; a.rel = 'noopener noreferrer'; a.target = '_blank';
      contacts.append(a);
      document.querySelectorAll(`[data-social="${name}"]`).forEach(link => {
        link.href = url.href; link.target = '_blank'; link.rel = 'noopener noreferrer'; link.removeAttribute('aria-disabled');
      });
    } catch {}
  }
  for (const element of document.querySelectorAll('[data-fact]')) {
    if (business[element.dataset.fact]) element.textContent = business[element.dataset.fact];
  }
})();
