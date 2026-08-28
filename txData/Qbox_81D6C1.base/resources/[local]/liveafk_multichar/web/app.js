(() => {
  const app = document.getElementById('app');
  const state = {
    characters: [],
    maxSlots: 1,
    selected: null,
    gender: 0,
    stage: 1,
    allowDelete: true,
    pendingDelete: null,
    deleting: false,
  };

  const $ = (id) => document.getElementById(id);

  function resourceName() {
    if (typeof window.GetParentResourceName === 'function') {
      try { return window.GetParentResourceName(); } catch (_) {}
    }
    return 'liveafk_multichar';
  }

  function post(name, data = {}) {
    return fetch(`https://${resourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    }).then(async (r) => {
      const t = await r.text();
      if (!t) return {};
      try { return JSON.parse(t); } catch (_) { return {}; }
    }).catch(() => ({}));
  }

  function money(n) {
    return `$${Number(n || 0).toLocaleString('fr-FR')}`;
  }

  function showView(name) {
    document.querySelectorAll('.view').forEach((v) => v.classList.toggle('active', v.id === `view-${name}`));
  }

  function setStage(n) {
    state.stage = n;
    document.querySelectorAll('.step').forEach((s) => s.classList.toggle('active', Number(s.dataset.step) === n));
    document.querySelectorAll('.form-stage').forEach((s) => s.classList.toggle('active', Number(s.dataset.stage) === n));
    if (n === 3) renderSummary();
  }

  function renderSummary() {
    $('summary').innerHTML = `
      <div><strong>${escapeHtml($('firstname').value)} ${escapeHtml($('lastname').value)}</strong></div>
      <div>${state.gender === 0 ? 'Homme' : 'Femme'} · ${escapeHtml($('nationality').value)}</div>
      <div>Ne(e) le ${escapeHtml($('birthdate').value)}</div>
    `;
  }

  function escapeHtml(str) {
    return String(str || '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  }

  function toast(msg, type) {
    const el = $('toast');
    el.textContent = msg;
    el.className = `toast ${type || 'ok'}`;
    clearTimeout(toast._t);
    toast._t = setTimeout(() => el.classList.add('hidden'), 2800);
  }

  function openConfirm(ch) {
    state.pendingDelete = ch;
    $('confirmText').textContent = `Supprimer ${ch.firstname} ${ch.lastname} ? Action definitive.`;
    $('confirmModal').classList.remove('hidden');
  }

  function closeConfirm() {
    state.pendingDelete = null;
    $('confirmModal').classList.add('hidden');
  }

  async function doDelete() {
    const ch = state.pendingDelete;
    if (!ch || state.deleting) return;
    state.deleting = true;
    $('confirmOk').disabled = true;
    $('confirmOk').textContent = 'Suppression...';

    const res = await post('delete', { citizenid: ch.citizenid });

    state.deleting = false;
    $('confirmOk').disabled = false;
    $('confirmOk').textContent = 'Supprimer';
    closeConfirm();

    if (!res || !res.ok) {
      toast(res?.error || 'Suppression refusee', 'err');
      return;
    }

    if (Array.isArray(res.characters)) {
      state.characters = res.characters;
      if (res.maxSlots) state.maxSlots = res.maxSlots;
      state.selected = state.characters[0]?.citizenid || null;
      $('btnCreate').style.display = state.characters.length >= state.maxSlots ? 'none' : '';
      renderSlots();
    }

    toast('Personnage supprime', 'ok');
  }

  function renderSlots() {
    const box = $('slots');
    box.innerHTML = '';
    $('slotMeta').textContent = `${state.characters.length} / ${state.maxSlots} slots`;

    if (!state.characters.length) {
      box.innerHTML = '<p class="hint">Aucun personnage. Cree ta premiere identite.</p>';
      return;
    }

    state.characters.forEach((ch, idx) => {
      const el = document.createElement('div');
      el.className = `slot${state.selected === ch.citizenid ? ' active' : ''}`;
      el.innerHTML = `
        <span class="slot__id">0${idx + 1}</span>
        <div>
          <div class="slot__name">${escapeHtml(ch.firstname)} ${escapeHtml(ch.lastname)}</div>
          <div class="slot__meta">${escapeHtml(ch.job)} · ${money(ch.cash)} / ${money(ch.bank)} · ${escapeHtml(ch.birthdate)}</div>
        </div>
        <div class="slot__actions">
          <button type="button" class="btn primary sm" data-play="${escapeHtml(ch.citizenid)}">Jouer</button>
          ${state.allowDelete ? `<button type="button" class="btn danger sm" data-del="${escapeHtml(ch.citizenid)}">Suppr.</button>` : ''}
        </div>
      `;
      el.addEventListener('click', (e) => {
        if (e.target.closest('button')) return;
        state.selected = ch.citizenid;
        post('preview', { citizenid: ch.citizenid });
        renderSlots();
      });
      el.querySelector('[data-play]')?.addEventListener('click', (e) => {
        e.stopPropagation();
        post('play', { citizenid: ch.citizenid });
      });
      el.querySelector('[data-del]')?.addEventListener('click', (e) => {
        e.stopPropagation();
        openConfirm(ch);
      });
      box.appendChild(el);
    });
  }

  function fillNationalities(list) {
    const sel = $('nationality');
    sel.innerHTML = '';
    (list || []).forEach((n) => {
      const opt = document.createElement('option');
      opt.value = n;
      opt.textContent = n;
      sel.appendChild(opt);
    });
  }

  function openUI(data) {
    state.characters = data.characters || [];
    state.maxSlots = data.maxSlots || 1;
    state.allowDelete = !!data.allowDelete;
    state.selected = state.characters[0]?.citizenid || null;

    $('brandLive').textContent = data.brand?.live || 'ACARDIA';
    $('brandAfk').textContent = data.brand?.afk || 'RP V2';
    $('brandServer').textContent = data.brand?.server || 'Acardia RP V2';
    $('tagline').textContent = data.brand?.tagline || '';

    fillNationalities(data.nationalities);
    $('birthdate').min = data.dateMin || '1900-01-01';
    $('birthdate').max = data.dateMax || '2006-12-31';
    $('birthdate').value = data.dateMax || '2000-01-01';

    $('btnCreate').style.display = state.characters.length >= state.maxSlots ? 'none' : '';

    renderSlots();
    setStage(1);
    showView('select');
    app.classList.remove('hidden');
  }

  $('confirmCancel').addEventListener('click', () => {
    if (state.deleting) return;
    closeConfirm();
  });
  $('confirmOk').addEventListener('click', () => doDelete());

  $('btnCreate').addEventListener('click', () => {
    showView('create');
    setStage(1);
    post('previewGender', { gender: state.gender });
  });

  document.querySelectorAll('[data-nav="select"]').forEach((b) => {
    b.addEventListener('click', () => {
      showView('select');
      post('backToSelect', { citizenid: state.selected });
    });
  });
  document.querySelectorAll('[data-next]').forEach((b) => {
    b.addEventListener('click', () => {
      const next = Number(b.dataset.next);
      if (next === 2) {
        if (!$('firstname').value.trim() || !$('lastname').value.trim()) return;
      }
      if (next === 3) {
        if (!$('birthdate').value) return;
      }
      setStage(next);
    });
  });
  document.querySelectorAll('[data-prev]').forEach((b) => {
    b.addEventListener('click', () => setStage(Number(b.dataset.prev)));
  });

  document.querySelectorAll('.gender__btn').forEach((b) => {
    b.addEventListener('click', () => {
      state.gender = Number(b.dataset.gender);
      document.querySelectorAll('.gender__btn').forEach((x) => x.classList.toggle('active', x === b));
      post('previewGender', { gender: state.gender });
    });
  });

  $('btnConfirm').addEventListener('click', async () => {
    const res = await post('create', {
      firstname: $('firstname').value.trim(),
      lastname: $('lastname').value.trim(),
      nationality: $('nationality').value,
      birthdate: $('birthdate').value,
      gender: state.gender,
    });
    if (!res.ok) {
      toast(res.error || 'Creation refusee', 'err');
    }
  });

  window.addEventListener('message', (e) => {
    const { action, data } = e.data || {};
    if (action === 'open') openUI(data || {});
    if (action === 'refresh') openUI(data || {});
    if (action === 'close') app.classList.add('hidden');
  });
})();
