(() => {
  const IMAGE_FALLBACK = 'nui://ox_inventory/web/images';

  const GEAR = [
    { id: 'hat', label: 'Tete', icon: '🎩', side: 'left', kind: 'prop', index: 0 },
    { id: 'mask', label: 'Masque', icon: '🎭', side: 'left', kind: 'component', index: 1 },
    { id: 'glasses', label: 'Lunettes', icon: '👓', side: 'left', kind: 'prop', index: 1 },
    { id: 'ears', label: 'Oreilles', icon: '🎧', side: 'left', kind: 'prop', index: 2 },
    { id: 'chain', label: 'Chaine', icon: '📿', side: 'left', kind: 'component', index: 7 },
    { id: 'jacket', label: 'Torse', icon: '🧥', side: 'right', kind: 'component', index: 11 },
    { id: 'vest', label: 'Gilet', icon: '🦺', side: 'right', kind: 'component', index: 9 },
    { id: 'bag', label: 'Sac', icon: '🎒', side: 'right', kind: 'component', index: 5 },
    { id: 'gloves', label: 'Gants', icon: '🧤', side: 'right', kind: 'component', index: 3 },
    { id: 'pants', label: 'Pantalon', icon: '👖', side: 'right', kind: 'component', index: 4 },
    { id: 'shoes', label: 'Chaussures', icon: '👟', side: 'left', kind: 'component', index: 6 },
    { id: 'watch', label: 'Montre', icon: '⌚', side: 'right', kind: 'prop', index: 6 },
    { id: 'bracelet', label: 'Bracelet', icon: '🧿', side: 'right', kind: 'prop', index: 7 },
  ];

  const state = {
    open: false,
    left: null,
    right: null,
    items: {},
    imagepath: IMAGE_FALLBACK,
    selected: null, // { inventory: 'left'|'right', slot: number }
    amount: 0,
    drag: null,
    gearOff: {},
    locales: {},
  };

  const $ = (id) => document.getElementById(id);
  const app = $('app');

  function resourceName() {
    if (typeof GetParentResourceName === 'function') {
      try { return GetParentResourceName(); } catch (_) {}
    }
    return 'ox_inventory';
  }

  function post(name, data) {
    return fetch(`https://${resourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: data === undefined ? '{}' : JSON.stringify(data),
    }).then(async (r) => {
      const t = await r.text();
      if (!t) return null;
      try { return JSON.parse(t); } catch (_) { return t; }
    }).catch(() => null);
  }

  function kg(g) {
    return (Number(g || 0) / 1000).toFixed(2).replace(/\.00$/, '');
  }

  function itemInfo(name) {
    return state.items[name] || state.items[(name || '').toLowerCase()] || {};
  }

  function imageFor(item) {
    if (!item || !item.name) return '';
    const info = itemInfo(item.name);
    if (item.metadata?.imageurl) return item.metadata.imageurl;
    if (item.metadata?.image) return `${state.imagepath}/${item.metadata.image}.png`;
    if (info.image) return info.image.startsWith('http') || info.image.startsWith('nui://')
      ? info.image
      : `${state.imagepath}/${info.image}`;
    return `${state.imagepath}/${item.name.toLowerCase()}.png`;
  }

  function labelFor(item) {
    if (!item || !item.name) return '';
    return item.metadata?.label || itemInfo(item.name).label || item.name;
  }

  function normalizeSlots(inv) {
    if (!inv) return [];
    const slots = Number(inv.slots) || 50;
    const out = Array.from({ length: slots }, (_, i) => ({ slot: i + 1 }));
    const raw = inv.items;
    if (!raw) return out;

    const apply = (it) => {
      if (!it || !it.slot || !it.name) return;
      const idx = it.slot - 1;
      if (idx >= 0 && idx < out.length) out[idx] = { ...out[idx], ...it };
    };

    if (Array.isArray(raw)) {
      raw.forEach(apply);
    } else {
      Object.values(raw).forEach(apply);
    }
    return out;
  }

  function invBySide(side) {
    return side === 'right' ? state.right : state.left;
  }

  function typeOf(side) {
    const inv = invBySide(side);
    if (side === 'left') return 'player';
    const t = inv?.type;
    if (!t || t === '') return 'newdrop';
    // ox attend "stash" / "trunk" / "glovebox" / "drop" / "newdrop" / "container" / etc.
    return t;
  }

  function findItem(side, slot) {
    const slotNum = Number(slot);
    const slots = normalizeSlots(invBySide(side));
    return slots.find((s) => Number(s.slot) === slotNum && s.name) || null;
  }

  function setWeight(el, inv) {
    if (!inv) {
      el.textContent = '';
      return;
    }
    el.textContent = `${kg(inv.weight)} / ${kg(inv.maxWeight)} kg`;
  }

  function renderGear() {
    const left = $('gearLeft');
    const right = $('gearRight');
    left.innerHTML = '';
    right.innerHTML = '';

    GEAR.forEach((g) => {
      const el = document.createElement('button');
      el.type = 'button';
      el.className = `gear-slot ${state.gearOff[g.id] ? 'off' : 'on'}`;
      el.dataset.gear = g.id;
      el.innerHTML = `<span class="gear-slot__icon">${g.icon}</span><span class="gear-slot__name">${g.label}</span>`;
      el.title = state.gearOff[g.id] ? `Remettre — ${g.label}` : `Retirer — ${g.label}`;
      el.addEventListener('click', () => {
        post('toggleClothing', { id: g.id, kind: g.kind, index: g.index });
        state.gearOff[g.id] = !state.gearOff[g.id];
        renderGear();
      });
      (g.side === 'left' ? left : right).appendChild(el);
    });
  }

  let ghostEl = null;
  let dragActive = false;
  let dragMoved = false;
  let suppressClick = false;

  function ensureGhost() {
    if (ghostEl) return ghostEl;
    ghostEl = document.createElement('div');
    ghostEl.className = 'drag-ghost hidden';
    document.body.appendChild(ghostEl);
    return ghostEl;
  }

  function startPointerDrag(e, side, item) {
    if (!item?.name || e.button !== 0) return;
    e.preventDefault();
    hideTip();
    closeCtx();

    dragActive = true;
    dragMoved = false;
    state.drag = { side, slot: Number(item.slot), item };
    state.selected = { side, slot: Number(item.slot) };

    const g = ensureGhost();
    g.innerHTML = '';
    const img = document.createElement('img');
    img.src = imageFor(item);
    img.onerror = () => { img.style.opacity = '0.2'; };
    g.appendChild(img);
    g.classList.remove('hidden');
    g.style.left = `${e.clientX}px`;
    g.style.top = `${e.clientY}px`;

    document.querySelectorAll('.slot.dragging-source').forEach((n) => n.classList.remove('dragging-source'));
    const src = document.querySelector(`.slot[data-side="${side}"][data-slot="${item.slot}"]`);
    if (src) src.classList.add('dragging-source');
  }

  function onPointerMove(e) {
    if (!dragActive || !state.drag) return;
    dragMoved = true;
    const g = ensureGhost();
    g.style.left = `${e.clientX}px`;
    g.style.top = `${e.clientY}px`;

    document.querySelectorAll('.slot.drag-over').forEach((n) => n.classList.remove('drag-over'));
    const under = document.elementFromPoint(e.clientX, e.clientY);
    const slot = under?.closest?.('.slot');
    if (slot) slot.classList.add('drag-over');
  }

  async function onPointerUp(e) {
    if (!dragActive) return;
    dragActive = false;

    const g = ensureGhost();
    g.classList.add('hidden');
    document.querySelectorAll('.slot.dragging-source, .slot.drag-over').forEach((n) => {
      n.classList.remove('dragging-source', 'drag-over');
    });

    const from = state.drag;
    state.drag = null;

    if (!from) return;

    if (!dragMoved) {
      // simple click select
      state.selected = { side: from.side, slot: from.slot };
      renderAll();
      return;
    }

    suppressClick = true;
    setTimeout(() => { suppressClick = false; }, 80);

    const under = document.elementFromPoint(e.clientX, e.clientY);
    const target = under?.closest?.('.slot');
    if (!target) return;

    const toSide = target.dataset.side;
    const toSlot = Number(target.dataset.slot);
    if (!toSide || !toSlot) return;
    if (toSide === from.side && toSlot === from.slot) return;

    await doSwap(from.side, from.slot, toSide, toSlot);
  }

  document.addEventListener('mousemove', onPointerMove);
  document.addEventListener('mouseup', onPointerUp);

  function renderSlotEl(item, side, opts = {}) {
    const el = document.createElement('div');
    const has = !!(item && item.name);
    const slotNum = Number(item.slot);
    el.className = 'slot';
    el.dataset.side = side;
    el.dataset.slot = String(slotNum);

    if (opts.hot) el.classList.add('hot');
    if (state.selected && state.selected.side === side && Number(state.selected.slot) === slotNum) {
      el.classList.add('selected');
    }

    if (opts.hotkey) {
      const hk = document.createElement('span');
      hk.className = 'slot__hotkey';
      hk.textContent = String(opts.hotkey);
      el.appendChild(hk);
    }

    if (has) {
      const img = document.createElement('img');
      img.src = imageFor(item);
      img.alt = labelFor(item);
      img.draggable = false;
      img.onerror = () => { img.style.opacity = '0.15'; };
      el.appendChild(img);

      if (item.count > 1 || item.name === 'money') {
        const c = document.createElement('span');
        c.className = 'slot__count';
        c.textContent = `×${item.count}`;
        el.appendChild(c);
      }

      const lbl = document.createElement('span');
      lbl.className = 'slot__label';
      lbl.textContent = labelFor(item);
      el.appendChild(lbl);

      el.addEventListener('mouseenter', (e) => {
        if (dragActive) return;
        showTip(e, item);
        if (item.name === 'clothing' && item.metadata) {
          post('previewClothing', { metadata: item.metadata });
        }
      });
      el.addEventListener('mousemove', (e) => { if (!dragActive) moveTip(e); });
      el.addEventListener('mouseleave', () => {
        hideTip();
        if (item.name === 'clothing') post('clearPreview', {});
      });
    }

    el.addEventListener('mousedown', (e) => {
      if (!has) return;
      startPointerDrag(e, side, item);
    });

    el.addEventListener('click', (e) => {
      if (suppressClick || dragMoved) return;
      if (!has) {
        state.selected = null;
        renderAll();
        return;
      }
      state.selected = { side, slot: slotNum };
      renderAll();
    });

    el.addEventListener('dblclick', () => {
      if (has && side === 'left') post('useItem', slotNum);
    });

    el.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      if (!has) return;
      state.selected = { side, slot: slotNum };
      openCtx(e.clientX, e.clientY, item, side);
    });

    return el;
  }

  function renderGrid(container, inv, side) {
    container.innerHTML = '';
    if (!inv) return;
    const slots = normalizeSlots(inv);
    slots.forEach((item, i) => {
      container.appendChild(renderSlotEl(item, side, {
        hot: side === 'left' && i < 5,
        hotkey: side === 'left' && i < 5 ? i + 1 : null,
      }));
    });
  }

  function renderHotbar(targetId) {
    const box = $(targetId);
    if (!box) return;
    box.innerHTML = '';
    const slots = normalizeSlots(state.left || { slots: 5, items: [] }).slice(0, 5);
    while (slots.length < 5) slots.push({ slot: slots.length + 1 });
    slots.forEach((item, i) => {
      box.appendChild(renderSlotEl(item, 'left', { hot: true, hotkey: i + 1 }));
    });
  }

  function showTip(e, item) {
    const tip = $('tooltip');
    const info = itemInfo(item.name);
    const weight = item.weight != null ? item.weight : info.weight;
    tip.innerHTML = `
      <strong>${escapeHtml(labelFor(item))}</strong>
      <div>${escapeHtml(info.description || '')}</div>
      <div class="meta">${item.count || 1}x · ${kg(weight)} kg${item.metadata?.type ? ` · ${escapeHtml(String(item.metadata.type))}` : ''}</div>
    `;
    tip.classList.remove('hidden');
    moveTip(e);
  }

  function moveTip(e) {
    const tip = $('tooltip');
    if (tip.classList.contains('hidden')) return;
    const x = Math.min(e.clientX + 14, window.innerWidth - 260);
    const y = Math.min(e.clientY + 14, window.innerHeight - 120);
    tip.style.left = `${x}px`;
    tip.style.top = `${y}px`;
  }

  function hideTip() {
    $('tooltip').classList.add('hidden');
  }

  function escapeHtml(s) {
    return String(s || '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  }

  function openCtx(x, y, item, side) {
    const ctx = $('ctx');
    ctx.innerHTML = '';
    const add = (label, fn) => {
      const b = document.createElement('button');
      b.type = 'button';
      b.textContent = label;
      b.addEventListener('click', () => { closeCtx(); fn(); });
      ctx.appendChild(b);
    };

    if (side === 'left') {
      add('Utiliser', () => post('useItem', item.slot));
      add('Donner', () => post('giveItem', { slot: item.slot, count: amountToGive(item) }));
    }
    if (state.right && typeOf('right') === 'shop' && side === 'right') {
      add('Acheter', () => buyItem(item));
    }
    if (state.right && typeOf('right') === 'crafting' && side === 'right') {
      add('Craft', () => post('craftItem', { fromSlot: item.slot, toSlot: 1, count: 1 }));
    }
    add('Fermer', () => {});

    ctx.classList.remove('hidden');
    ctx.style.left = `${Math.min(x, window.innerWidth - 160)}px`;
    ctx.style.top = `${Math.min(y, window.innerHeight - 160)}px`;
  }

  function closeCtx() {
    $('ctx').classList.add('hidden');
  }

  function amountToGive(item) {
    const n = Number(state.amount) || 0;
    if (n <= 0) return item.count || 1;
    return Math.min(n, item.count || 1);
  }

  async function doSwap(fromSide, fromSlot, toSide, toSlot) {
    fromSlot = Number(fromSlot);
    toSlot = Number(toSlot);
    const fromItem = findItem(fromSide, fromSlot);
    if (!fromItem) return;

    const count = amountToGive(fromItem);
    const fromType = typeOf(fromSide);
    const toType = typeOf(toSide);

    if (toType === 'shop') return;
    if (fromType === 'shop') {
      await buyItem(fromItem, toSlot);
      return;
    }
    if (fromType === 'crafting') {
      await post('craftItem', { fromSlot, toSlot, count: 1 });
      return;
    }

    const ok = await post('swapItems', {
      fromSlot,
      toSlot,
      fromType,
      toType,
      count,
    });

    if (ok === false) return;
  }

  async function buyItem(item, toSlot) {
    const count = amountToGive(item);
    await post('buyItem', {
      fromSlot: item.slot,
      toSlot: toSlot || (state.selected?.side === 'left' ? state.selected.slot : 1),
      count,
    });
  }

  function renderAll() {
    const hasRight = !!(state.right && state.right.type && state.right.type !== 'newdrop');
    // show right also for newdrop when explicitly opened with items/slots useful — ox always sends right
    const showRight = !!(state.right && (state.right.type !== 'newdrop' || (state.right.label || state.openSecondary)));

    // Actually ox always has right as newdrop by default when opening player-only.
    // Stock UI shows both. We'll show right always when open, labeled "Sol" for newdrop.
    const rightVisible = !!state.right;

    document.querySelector('.layout')?.classList.toggle('solo', !rightVisible);

    if (state.left) {
      $('leftLabel').textContent = state.left.label || 'Poches';
      $('leftSub').textContent = state.left.id != null ? String(state.left.id) : 'Inventaire';
      setWeight($('leftWeight'), state.left);
      renderGrid($('leftGrid'), state.left, 'left');
    }

    if (rightVisible) {
      $('panelRight').classList.remove('hidden');
      const labels = {
        newdrop: 'Sol',
        drop: 'Drop',
        trunk: 'Coffre',
        glovebox: 'Boite a gants',
        stash: 'Stockage',
        shop: 'Boutique',
        crafting: 'Craft',
        player: 'Joueur',
        container: 'Conteneur',
        policeevidence: 'Preuves',
      };
      $('rightLabel').textContent = state.right.label || labels[state.right.type] || 'Secondaire';
      $('rightSub').textContent = state.right.type || '—';
      setWeight($('rightWeight'), state.right);
      renderGrid($('rightGrid'), state.right, 'right');
    } else {
      $('panelRight').classList.add('hidden');
    }

    renderHotbar('hotbar'); // masquee en CSS quand #app ouvert
  }

  function openInventory(data) {
    state.open = true;
    state.left = data.leftInventory || null;
    state.right = data.rightInventory || null;
    if (state.left) {
      state.left.type = 'player';
      if (!state.left.label) state.left.label = 'Poches';
    }
    state.gearOff = {};
    dragActive = false;
    state.drag = null;
    app.classList.remove('hidden');
    $('hotbarOnly').classList.add('hidden');
    renderGear();
    renderAll();
    post('invReady', {});
  }

  function closeInventory() {
    state.open = false;
    state.selected = null;
    state.drag = null;
    hideTip();
    closeCtx();
    post('clearPreview', {});
    app.classList.add('hidden');
  }

  function applyRefresh(payload) {
    const list = payload?.items;
    if (!list) return;

    const leftId = state.left?.id;
    const rightId = state.right?.id;

    list.forEach((entry) => {
      const item = entry.item;
      if (!item || item.slot == null) return;

      const invKey = entry.inventory;
      let target = null;

      if (
        invKey === 'player' ||
        invKey === leftId ||
        String(invKey) === String(leftId)
      ) {
        target = state.left;
      } else if (
        state.right && (
          invKey === rightId ||
          String(invKey) === String(rightId) ||
          invKey === state.right.type ||
          invKey === 'shop'
        )
      ) {
        target = state.right;
      } else if (state.right && invKey !== 'player') {
        target = state.right;
      } else {
        target = state.left;
      }

      if (!target) return;

      if (!target.items) target.items = {};
      if (Array.isArray(target.items)) {
        const map = {};
        target.items.forEach((it) => { if (it && it.slot) map[it.slot] = it; });
        target.items = map;
      }

      if (item.name && item.count) {
        target.items[item.slot] = item;
      } else {
        delete target.items[item.slot];
      }
    });

    if (payload.weight != null && state.left) {
      state.left.weight = payload.weight;
    }
    renderAll();
  }

  // Controls
  $('btnClose').addEventListener('click', () => post('exit'));
  $('btnUse').addEventListener('click', () => {
    if (!state.selected || state.selected.side !== 'left') return;
    post('useItem', state.selected.slot);
  });
  $('btnGive').addEventListener('click', () => {
    if (!state.selected || state.selected.side !== 'left') return;
    const item = findItem('left', state.selected.slot);
    if (!item) return;
    post('giveItem', { slot: item.slot, count: amountToGive(item) });
  });
  $('itemAmount').addEventListener('input', (e) => {
    state.amount = Math.max(0, Number(e.target.value) || 0);
  });

  document.addEventListener('click', (e) => {
    if (!e.target.closest('#ctx')) closeCtx();
  });

  document.addEventListener('keydown', (e) => {
    if (!state.open) return;
    if (e.key === 'Escape') post('exit');
  });

  window.addEventListener('message', (e) => {
    const { action, data } = e.data || {};
    if (action === 'init') {
      state.items = data?.items || {};
      state.imagepath = data?.imagepath || IMAGE_FALLBACK;
      state.locales = data?.locale || {};
      if (data?.leftInventory) state.left = data.leftInventory;
      return;
    }
    if (action === 'setupInventory') {
      openInventory(data || {});
      return;
    }
    if (action === 'refreshSlots') {
      applyRefresh(data || {});
      return;
    }
    if (action === 'closeInventory') {
      closeInventory();
      return;
    }
    if (action === 'toggleHotbar') {
      if (state.open) return;
      const box = $('hotbarOnly');
      const show = box.classList.contains('hidden');
      if (show) {
        // need left items — use last known
        renderHotbar('hotbarOnly');
        box.classList.remove('hidden');
      } else {
        box.classList.add('hidden');
      }
      return;
    }
    if (action === 'displayMetadata') return;
  });

  // Boot
  post('uiLoaded');
})();
