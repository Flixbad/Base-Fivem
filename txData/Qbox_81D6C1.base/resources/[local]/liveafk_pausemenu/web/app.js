(() => {
  const app = document.getElementById('app');
  const state = {
    actions: [],
    selected: 0,
    discord: '',
  };

  const $ = (id) => document.getElementById(id);

  function resourceName() {
    if (typeof GetParentResourceName === 'function') {
      try { return GetParentResourceName(); } catch (_) {}
    }
    return 'liveafk_pausemenu';
  }

  function post(name, data = {}) {
    return fetch(`https://${resourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    }).catch(() => {});
  }

  function money(n) {
    return `$${Number(n || 0).toLocaleString('fr-FR')}`;
  }

  function pad(n) {
    return String(n).padStart(2, '0');
  }

  function highlightRail() {
    document.querySelectorAll('.item').forEach((el, i) => {
      el.classList.toggle('active', i === state.selected);
    });
  }

  function renderRail() {
    const rail = $('rail');
    rail.innerHTML = '';
    state.actions.forEach((a, i) => {
      const el = document.createElement('button');
      el.type = 'button';
      el.className = `item${i === state.selected ? ' active' : ''}`;
      el.innerHTML = `
        <span class="item__code">${a.code || pad(i + 1)}</span>
        <div class="item__body">
          <h3>${a.label}</h3>
          <p>${a.desc || ''}</p>
        </div>
        <span class="item__icon">${a.icon || '◆'}</span>
      `;
      el.addEventListener('mouseenter', () => {
        state.selected = i;
        highlightRail();
      });
      el.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        state.selected = i;
        highlightRail();
        trigger(a);
      });
      rail.appendChild(el);
    });
  }

  function trigger(action) {
    if (!action) return;
    if (action.id === 'discord' && state.discord) {
      // FiveM: invokeNative open url via NUI
      window.invokeNative?.('openUrl', state.discord);
      // fallback copy
      try { navigator.clipboard?.writeText(state.discord); } catch (_) {}
    }
    post('action', { id: action.id });
  }

  function openUI(data) {
    state.actions = data.actions || [];
    state.selected = 0;
    state.discord = data.discord || '';

    $('brandLive').textContent = data.brand?.live || 'ACARDIA';
    $('brandAfk').textContent = data.brand?.afk || 'RP V2';
    $('brandServer').textContent = data.brand?.server || 'Acardia RP V2';
    $('tagline').textContent = data.brand?.tagline || 'L archive du destin';
    $('clockCity').textContent = data.brand?.city || 'Los Santos';

    const t = data.time || {};
    $('clockTime').textContent = `${pad(t.hour || 0)}:${pad(t.minute || 0)}`;
    $('onlineCount').textContent = String(data.online || 0);

    const p = data.player || {};
    $('playerName').textContent = p.name || 'Citoyen';
    $('playerJob').textContent = p.grade ? `${p.job} — ${p.grade}` : (p.job || 'Civil');
    $('playerCid').textContent = p.citizenid || '—';
    $('playerSid').textContent = String(p.serverId || 0);
    $('playerCash').textContent = money(p.cash);
    $('playerBank').textContent = money(p.bank);

    renderRail();
    app.classList.remove('hidden');
  }

  function closeUI() {
    app.classList.add('hidden');
  }

  document.addEventListener('keydown', (e) => {
    if (app.classList.contains('hidden')) return;
    if (e.key === 'Escape') {
      post('close');
      return;
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      state.selected = (state.selected + 1) % state.actions.length;
      highlightRail();
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault();
      state.selected = (state.selected - 1 + state.actions.length) % state.actions.length;
      highlightRail();
    }
    if (e.key === 'Enter') {
      e.preventDefault();
      trigger(state.actions[state.selected]);
    }
  });

  window.addEventListener('message', (e) => {
    const { action, data } = e.data || {};
    if (action === 'open') openUI(data || {});
    if (action === 'close') closeUI();
  });
})();
