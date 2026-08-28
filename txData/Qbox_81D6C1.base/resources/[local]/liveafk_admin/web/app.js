(() => {
  const app = document.getElementById('app');
  const modal = document.getElementById('modal');
  const state = {
    meta: null,
    players: [],
    reports: [],
    selectedId: null,
    modalResolve: null,
  };

  const $ = (id) => document.getElementById(id);

  // Ne JAMAIS ecraser window.GetParentResourceName (sinon close / callbacks cassent)
  function resourceName() {
    if (typeof window.GetParentResourceName === 'function') {
      try { return window.GetParentResourceName(); } catch (_) {}
    }
    return 'liveafk_admin';
  }

  function post(name, data = {}) {
    return fetch(`https://${resourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    }).then(async (r) => {
      const text = await r.text();
      if (!text) return {};
      try { return JSON.parse(text); } catch (_) { return {}; }
    }).catch(() => ({}));
  }

  function fmtUptime(sec) {
    sec = Math.max(0, Number(sec) || 0);
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
  }

  function money(n) {
    return `$${Number(n || 0).toLocaleString('fr-FR')}`;
  }

  function can(perm) {
    return !!(state.meta && state.meta.perms && state.meta.perms[perm]);
  }

  function applyPermNav() {
    document.querySelectorAll('.nav[data-perm]').forEach((btn) => {
      const perm = btn.getAttribute('data-perm');
      btn.style.display = can(perm) ? '' : 'none';
    });
  }

  function setDashboard(d) {
    if (!d) return;
    $('statPlayers').textContent = d.players ?? 0;
    $('statMax').textContent = `/ ${d.maxClients ?? 48}`;
    $('statStaff').textContent = d.staff ?? 0;
    $('statReports').textContent = d.reports ?? 0;
    $('statUptime').textContent = fmtUptime(d.uptime);
  }

  function selectedPlayer() {
    return state.players.find((p) => p.id === state.selectedId) || null;
  }

  function renderPlayers() {
    const q = ($('playerSearch').value || '').toLowerCase().trim();
    const list = $('playerList');
    list.innerHTML = '';

    const filtered = state.players.filter((p) => {
      if (!q) return true;
      const hay = `${p.id} ${p.name} ${p.charName} ${p.job} ${p.jobLabel} ${p.citizenid || ''}`.toLowerCase();
      return hay.includes(q);
    });

    if (!filtered.length) {
      list.innerHTML = '<p class="empty" style="padding:1rem;color:var(--muted)">Aucun joueur</p>';
      return;
    }

    filtered.forEach((p) => {
      const btn = document.createElement('button');
      btn.className = `player-row${p.id === state.selectedId ? ' active' : ''}`;
      btn.innerHTML = `
        <span class="player-row__id">#${p.id}</span>
        <div class="player-row__meta">
          <strong>${escapeHtml(p.charName || p.name)}</strong>
          <span>${escapeHtml(p.name)} · ${escapeHtml(p.jobLabel || p.job)}</span>
        </div>
        <span class="ping">${p.ping}ms</span>
      `;
      btn.addEventListener('click', () => {
        state.selectedId = p.id;
        renderPlayers();
        renderDetail();
      });
      list.appendChild(btn);
    });
  }

  function escapeHtml(str) {
    return String(str ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
  }

  function actionBtn(label, action, opts = {}) {
    const disabled = opts.perm && !can(opts.perm);
    return `<button class="btn ${opts.danger ? 'danger' : ''} ${opts.primary ? 'primary' : ''}" data-act="${action}" ${disabled ? 'disabled' : ''}>${label}</button>`;
  }

  function renderDetail() {
    const box = $('playerDetail');
    const p = selectedPlayer();
    if (!p) {
      box.innerHTML = '<p class="empty">Selectionne un joueur</p>';
      return;
    }

    const jobOptions = (state.meta.jobs || [])
      .map((j) => `<option value="${escapeHtml(j.name)}">${escapeHtml(j.label)}</option>`)
      .join('');

    box.innerHTML = `
      <h2>${escapeHtml(p.charName)}</h2>
      <p class="meta">ID ${p.id} · ${escapeHtml(p.name)} · ${escapeHtml(p.citizenid || 'N/A')}</p>
      <p class="meta">${escapeHtml(p.jobLabel)} (${escapeHtml(p.job)}) · grade ${p.grade} · ${p.onDuty ? 'En service' : 'Hors service'}</p>
      <p class="meta">Cash ${money(p.cash)} · Banque ${money(p.bank)} · ${p.frozen ? 'FREEZE' : 'Libre'}</p>

      <div class="actions-grid">
        ${actionBtn('Goto', 'goto', { perm: 'gotoPlayer' })}
        ${actionBtn('Bring', 'bring', { perm: 'bring' })}
        ${actionBtn('Spectate', 'spectate', { perm: 'spectate' })}
        ${actionBtn(p.frozen ? 'Unfreeze' : 'Freeze', 'freeze', { perm: 'freeze' })}
        ${actionBtn('Heal', 'heal', { perm: 'heal' })}
        ${actionBtn('Revive', 'revive', { perm: 'revive' })}
        ${actionBtn('Warn', 'warn', { perm: 'warn' })}
        ${actionBtn('Kick', 'kick', { perm: 'kick', danger: true })}
        ${actionBtn('Ban', 'ban', { perm: 'ban', danger: true })}
      </div>

      <div class="form" style="margin-top:0.9rem">
        <label>Argent (+/-)</label>
        <div class="row">
          <select id="moneyType">
            <option value="cash">Cash</option>
            <option value="bank">Banque</option>
          </select>
          <input id="moneyAmount" type="number" placeholder="ex: 5000 ou -500" />
          <button class="btn primary" data-act="money" ${can('money') ? '' : 'disabled'}>OK</button>
        </div>

        <label>Item</label>
        <div class="row">
          <input id="itemName" type="text" placeholder="nom item" />
          <input id="itemCount" type="number" value="1" min="1" style="max-width:90px" />
          <button class="btn primary" data-act="item" ${can('item') ? '' : 'disabled'}>Give</button>
        </div>

        <label>Job</label>
        <div class="row">
          <select id="jobName">${jobOptions}</select>
          <input id="jobGrade" type="number" value="0" min="0" style="max-width:90px" />
          <button class="btn primary" data-act="job" ${can('job') ? '' : 'disabled'}>Set</button>
        </div>
      </div>
    `;

    box.querySelectorAll('[data-act]').forEach((btn) => {
      btn.addEventListener('click', () => handlePlayerAction(btn.getAttribute('data-act')));
    });
  }

  async function openModal({ title, desc, fields = [], confirmLabel = 'Confirmer', danger = false }) {
    $('modalTitle').textContent = title;
    $('modalDesc').textContent = desc || '';
    const fieldsEl = $('modalFields');
    fieldsEl.innerHTML = '';

    fields.forEach((f) => {
      const label = document.createElement('label');
      label.textContent = f.label;
      fieldsEl.appendChild(label);
      let input;
      if (f.type === 'select') {
        input = document.createElement('select');
        (f.options || []).forEach((o) => {
          const opt = document.createElement('option');
          opt.value = o.value;
          opt.textContent = o.label;
          input.appendChild(opt);
        });
      } else {
        input = document.createElement('input');
        input.type = f.type || 'text';
        if (f.placeholder) input.placeholder = f.placeholder;
      }
      input.id = `mf_${f.name}`;
      input.dataset.name = f.name;
      fieldsEl.appendChild(input);
    });

    const confirmBtn = $('modalConfirm');
    confirmBtn.textContent = confirmLabel;
    confirmBtn.className = `btn ${danger ? 'danger' : 'primary'}`;
    modal.classList.remove('hidden');

    return new Promise((resolve) => {
      state.modalResolve = resolve;
    });
  }

  function closeModal(result) {
    modal.classList.add('hidden');
    if (state.modalResolve) {
      state.modalResolve(result);
      state.modalResolve = null;
    }
  }

  $('modalCancel').addEventListener('click', () => closeModal(null));
  $('modalConfirm').addEventListener('click', () => {
    const data = {};
    $('modalFields').querySelectorAll('[data-name]').forEach((el) => {
      data[el.dataset.name] = el.value;
    });
    closeModal(data);
  });

  async function doAction(action, payload = {}) {
    const res = await post('action', { action, payload });
    await refresh();
    return res;
  }

  async function handlePlayerAction(act) {
    const p = selectedPlayer();
    if (!p) return;

    if (['goto', 'bring', 'spectate', 'freeze', 'heal', 'revive'].includes(act)) {
      await doAction(act, { target: p.id });
      if (act === 'spectate') {
        closeUI();
        post('close');
      }
      return;
    }

    if (act === 'warn' || act === 'kick') {
      const data = await openModal({
        title: act === 'warn' ? 'Avertir' : 'Kick',
        desc: `${p.charName} (#${p.id})`,
        fields: [{ name: 'reason', label: 'Raison', placeholder: 'Raison…' }],
        confirmLabel: act === 'warn' ? 'Warn' : 'Kick',
        danger: act === 'kick',
      });
      if (!data) return;
      await doAction(act, { target: p.id, reason: data.reason });
      return;
    }

    if (act === 'ban') {
      const durations = (state.meta.banDurations || []).map((d) => ({
        value: String(d.hours),
        label: d.label,
      }));
      const data = await openModal({
        title: 'Bannir',
        desc: `${p.charName} (#${p.id})`,
        fields: [
          { name: 'reason', label: 'Raison', placeholder: 'Raison du ban…' },
          { name: 'hours', label: 'Duree', type: 'select', options: durations },
        ],
        confirmLabel: 'Ban',
        danger: true,
      });
      if (!data) return;
      await doAction('ban', { target: p.id, reason: data.reason, hours: Number(data.hours) });
      return;
    }

    if (act === 'money') {
      const amount = Number($('moneyAmount').value);
      const moneyType = $('moneyType').value;
      if (!amount) return;
      await doAction('money', { target: p.id, amount, moneyType });
      return;
    }

    if (act === 'item') {
      const item = $('itemName').value.trim();
      const count = Number($('itemCount').value || 1);
      if (!item) return;
      await doAction('item', { target: p.id, item, count });
      return;
    }

    if (act === 'job') {
      await doAction('job', {
        target: p.id,
        job: $('jobName').value,
        grade: Number($('jobGrade').value || 0),
      });
    }
  }

  function renderReports() {
    const list = $('reportList');
    list.innerHTML = '';
    if (!state.reports.length) {
      list.innerHTML = '<p class="empty" style="padding:1rem;color:var(--muted)">Aucun report</p>';
      return;
    }

    state.reports.forEach((r) => {
      const el = document.createElement('div');
      el.className = 'report-row';
      el.innerHTML = `
        <div class="report-row__top">
          <strong>#${r.id} · ${escapeHtml(r.charName || r.senderName)} (ID ${r.senderId})</strong>
          <span class="tag ${r.closed ? 'closed' : ''}">${r.closed ? 'Ferme' : (r.claimedBy ? `Pris: ${escapeHtml(r.claimedBy)}` : 'Ouvert')}</span>
        </div>
        <p class="report-row__msg">${escapeHtml(r.message)}</p>
        <div class="row actions">
          <button class="btn" data-r="goto" ${can('gotoPlayer') && !r.closed ? '' : 'disabled'}>Goto</button>
          <button class="btn primary" data-r="claim" ${r.closed ? 'disabled' : ''}>Prendre</button>
          <button class="btn danger" data-r="close" ${r.closed ? 'disabled' : ''}>Fermer</button>
        </div>
      `;
      el.querySelector('[data-r="goto"]')?.addEventListener('click', () => doAction('goto', { target: r.senderId }));
      el.querySelector('[data-r="claim"]')?.addEventListener('click', () => doAction('claimReport', { reportId: r.id }));
      el.querySelector('[data-r="close"]')?.addEventListener('click', () => doAction('closeReport', { reportId: r.id }));
      list.appendChild(el);
    });
  }

  function renderWorldChips() {
    const box = $('weatherChips');
    box.innerHTML = '';
    (state.meta.weathers || []).forEach((w) => {
      const b = document.createElement('button');
      b.className = 'chip';
      b.textContent = w;
      b.addEventListener('click', () => doAction('weather', { weather: w }));
      box.appendChild(b);
    });

    const qv = $('quickVeh');
    qv.innerHTML = '';
    (state.meta.quickVehicles || []).forEach((v) => {
      const b = document.createElement('button');
      b.className = 'chip';
      b.textContent = v.label;
      b.addEventListener('click', () => {
        $('vehModel').value = v.model;
        doAction('spawnVehicle', { model: v.model });
      });
      qv.appendChild(b);
    });
  }

  function showView(name) {
    document.querySelectorAll('.nav').forEach((n) => n.classList.toggle('active', n.dataset.view === name));
    document.querySelectorAll('.view').forEach((v) => v.classList.toggle('active', v.id === `view-${name}`));
  }

  async function refresh() {
    const data = await post('refresh');
    if (data.dashboard) setDashboard(data.dashboard);
    if (data.players) {
      state.players = data.players;
      renderPlayers();
      renderDetail();
    }
    if (data.reports) {
      state.reports = data.reports;
      renderReports();
    }
  }

  function openUI(payload) {
    state.meta = payload.meta;
    state.players = payload.players || [];
    state.reports = payload.reports || [];
    state.selectedId = null;

    $('serverName').textContent = `${payload.meta.brand?.server || 'Acardia RP V2'} · Admin`;
    $('staffBadge').textContent = (payload.meta.level || 'staff').toUpperCase();

    applyPermNav();
    setDashboard(payload.dashboard);
    renderPlayers();
    renderDetail();
    renderReports();
    renderWorldChips();
    showView('dashboard');
    app.classList.remove('hidden');
    requestAnimationFrame(restoreTabletPos);
  }

  function closeUI() {
    app.classList.add('hidden');
    modal.classList.add('hidden');
  }

  /* ---- Drag tablette ---- */
  const tablet = document.querySelector('.tablet');
  const topbar = document.querySelector('.topbar');
  const dragState = { active: false, ox: 0, oy: 0, moved: false };
  const POS_KEY = 'liveafk_admin_tablet_pos';

  function clamp(val, min, max) {
    return Math.min(max, Math.max(min, val));
  }

  function applyTabletPos(x, y) {
    const rect = tablet.getBoundingClientRect();
    const maxX = window.innerWidth - rect.width;
    const maxY = window.innerHeight - rect.height;
    const nx = clamp(x, 0, Math.max(0, maxX));
    const ny = clamp(y, 0, Math.max(0, maxY));
    tablet.style.left = `${nx}px`;
    tablet.style.top = `${ny}px`;
    tablet.style.transform = 'none';
    return { x: nx, y: ny };
  }

  function centerTablet() {
    const rect = tablet.getBoundingClientRect();
    applyTabletPos(
      (window.innerWidth - rect.width) / 2,
      (window.innerHeight - rect.height) / 2
    );
  }

  function restoreTabletPos() {
    try {
      const raw = localStorage.getItem(POS_KEY);
      if (!raw) {
        centerTablet();
        return;
      }
      const pos = JSON.parse(raw);
      if (typeof pos.x === 'number' && typeof pos.y === 'number') {
        requestAnimationFrame(() => applyTabletPos(pos.x, pos.y));
        return;
      }
    } catch (_) {}
    centerTablet();
  }

  function saveTabletPos() {
    const left = parseFloat(tablet.style.left);
    const top = parseFloat(tablet.style.top);
    if (Number.isFinite(left) && Number.isFinite(top)) {
      localStorage.setItem(POS_KEY, JSON.stringify({ x: left, y: top }));
    }
  }

  function isDragHandle(target) {
    if (!topbar.contains(target)) return false;
    if (target.closest('.icon-btn')) return false;
    if (target.closest('button')) return false;
    return true;
  }

  topbar.addEventListener('pointerdown', (e) => {
    if (e.button !== 0) return;
    if (!isDragHandle(e.target)) return;
    const rect = tablet.getBoundingClientRect();
    dragState.active = true;
    dragState.moved = false;
    dragState.ox = e.clientX - rect.left;
    dragState.oy = e.clientY - rect.top;
    tablet.classList.add('is-dragging');
    topbar.setPointerCapture(e.pointerId);
    e.preventDefault();
  });

  topbar.addEventListener('pointermove', (e) => {
    if (!dragState.active) return;
    dragState.moved = true;
    applyTabletPos(e.clientX - dragState.ox, e.clientY - dragState.oy);
  });

  function endDrag(e) {
    if (!dragState.active) return;
    dragState.active = false;
    tablet.classList.remove('is-dragging');
    try { topbar.releasePointerCapture(e.pointerId); } catch (_) {}
    if (dragState.moved) saveTabletPos();
  }

  topbar.addEventListener('pointerup', endDrag);
  topbar.addEventListener('pointercancel', endDrag);

  window.addEventListener('resize', () => {
    if (app.classList.contains('hidden')) return;
    const left = parseFloat(tablet.style.left);
    const top = parseFloat(tablet.style.top);
    if (Number.isFinite(left) && Number.isFinite(top)) applyTabletPos(left, top);
  });

  // double-clic barre = recentrer
  topbar.addEventListener('dblclick', (e) => {
    if (!isDragHandle(e.target)) return;
    centerTablet();
    saveTabletPos();
  });

  // Nav
  document.querySelectorAll('.nav').forEach((btn) => {
    btn.addEventListener('click', () => showView(btn.dataset.view));
  });

  $('btnClose').addEventListener('click', () => {
    closeUI();
    post('close');
  });
  $('btnRefresh').addEventListener('click', refresh);
  $('playerSearch').addEventListener('input', renderPlayers);

  $('btnSpawnVeh').addEventListener('click', () => {
    const model = $('vehModel').value.trim();
    if (model) doAction('spawnVehicle', { model });
  });
  $('btnFixVeh').addEventListener('click', () => doAction('fixVehicle'));
  $('btnFlipVeh').addEventListener('click', () => doAction('flipVehicle'));
  $('btnDelVeh').addEventListener('click', () => doAction('deleteVehicle'));
  $('btnAnnounce').addEventListener('click', () => {
    const message = $('announceMsg').value.trim();
    if (message) doAction('announce', { message });
  });
  $('btnTime').addEventListener('click', () => {
    doAction('time', {
      hour: Number($('timeHour').value || 12),
      minute: Number($('timeMin').value || 0),
    });
  });
  $('btnNoclip').addEventListener('click', async () => {
    const res = await post('toggleNoclip');
    if (res.enabled) $('btnNoclip').textContent = 'Noclip ON';
    else $('btnNoclip').textContent = 'Toggle Noclip';
  });
  $('btnStopSpec').addEventListener('click', () => post('stopSpectate'));
  $('btnCoords').addEventListener('click', async () => {
    const res = await post('copyCoords');
    if (res.text) {
      $('coordsOut').textContent = res.text;
      try { await navigator.clipboard.writeText(res.text); } catch (_) {}
    }
  });

  window.addEventListener('message', (e) => {
    const { action, data } = e.data || {};
    if (action === 'open') openUI(data);
    if (action === 'close') closeUI();
    if (action === 'reportPing' && data) {
      state.reports.unshift(data);
      renderReports();
      setDashboard({
        players: Number($('statPlayers').textContent) || 0,
        maxClients: Number(($('statMax').textContent || '').replace(/\D/g, '')) || 48,
        staff: Number($('statStaff').textContent) || 0,
        reports: (Number($('statReports').textContent) || 0) + 1,
        uptime: 0,
      });
    }
  });

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (!modal.classList.contains('hidden')) closeModal(null);
      else {
        closeUI();
        post('close');
      }
    }
  });
})();
