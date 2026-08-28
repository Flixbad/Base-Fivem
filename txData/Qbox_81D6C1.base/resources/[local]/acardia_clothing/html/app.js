(function () {
  const $ = (s) => document.querySelector(s);
  const root = $('#root');
  const catSidebar = $('#catSidebar');
  const itemsGrid = $('#itemsGrid');
  const catTitle = $('#catTitle');
  const catCount = $('#catCount');
  const searchInput = $('#searchInput');
  const outfitPriceLabel = $('#outfitPriceLabel');
  const singlePriceLabel = $('#singlePriceLabel');
  const toast = $('#toast');
  const rotateZone = $('#rotateZone');
  const payModal = $('#payModal');
  const payBody = $('#payBody');
  const payTitle = $('#payTitle');
  const payAmount = $('#payAmount');
  let dragging = false;
  let lastMouseX = 0;
  let payResolve = null;

  const ICONS = {
    mask: '<svg viewBox="0 0 24 24"><path d="M12 4C7 4 3 6 3 9v3c0 4 4 7 9 7s9-3 9-7V9c0-3-4-5-9-5zm0 2c4 0 7 1.5 7 3s-3 3-7 3-7-1.5-7-3 3-3 7-3z"/></svg>',
    hat: '<svg viewBox="0 0 24 24"><path d="M4 15l8-4 8 4-1 2H5l-1-2zm8-8a6 6 0 016 6H6a6 6 0 016-6z"/></svg>',
    glasses: '<svg viewBox="0 0 24 24"><path d="M4 8h4a4 4 0 008 0h4v2h-1.2a3 3 0 01-5.6 0H10.8a3 3 0 01-5.6 0H4V8zm0 4h2.2a5 5 0 009.6 0H20v4H4v-4z"/></svg>',
    ear: '<svg viewBox="0 0 24 24"><circle cx="8" cy="12" r="3"/><circle cx="16" cy="12" r="3"/></svg>',
    shirt: '<svg viewBox="0 0 24 24"><path d="M16 3l4 3-2 2v13H6V8L4 6l4-3 4 3 4-3z"/></svg>',
    torso: '<svg viewBox="0 0 24 24"><path d="M12 2l4 4v3h4v14H4V9h4V6l4-4z"/></svg>',
    pants: '<svg viewBox="0 0 24 24"><path d="M8 3h8l1 7-2 11h-4l-1-7-1 7H7L5 10l1-7z"/></svg>',
    shoes: '<svg viewBox="0 0 24 24"><path d="M3 18h18v2H3v-2zm2-4l2-8h10l2 8H5z"/></svg>',
    bag: '<svg viewBox="0 0 24 24"><path d="M8 6V4a4 4 0 018 0v2h4v14H4V6h4zm2 0h4V4a2 2 0 00-4 0v2z"/></svg>',
    vest: '<svg viewBox="0 0 24 24"><path d="M7 3h10l2 4v14H5V7l2-4zm2 4v12h6V7H9z"/></svg>',
    accessory: '<svg viewBox="0 0 24 24"><path d="M12 2a5 5 0 00-5 5c0 2.5 2 4 5 7 3-3 5-4.5 5-7a5 5 0 00-5-5z"/></svg>',
    decals: '<svg viewBox="0 0 24 24"><path d="M4 4h16v16H4V4zm2 2v12h12V6H6z"/></svg>',
    watch: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 8v4l3 2"/></svg>',
    bracelet: '<svg viewBox="0 0 24 24"><ellipse cx="12" cy="12" rx="8" ry="4" fill="none" stroke="currentColor" stroke-width="2"/></svg>',
  };

  const PREVIEW = '<svg viewBox="0 0 64 64"><path d="M20 8h24l6 8v36H14V16l6-8zm4 8v32h16V16H24z" fill="currentColor"/></svg>';

  const state = {
    categories: [],
    category: null,
    items: [],
    selected: null,
    favorites: JSON.parse(localStorage.getItem('acardia_clothing_fav') || '[]'),
    favFilter: false,
    prices: { item: 100, hanger: 5 },
    outfitChanges: 0,
    outfitPrice: 0,
    gender: 'male',
    thumbCache: {},
    itemTextures: {},
  };

  let thumbObserver = null;

  function itemTexture(item) {
    const key = `${state.category.id}:${item.drawable}`;
    return state.itemTextures[key] ?? item.texture ?? 0;
  }

  function setItemTexture(item, texture) {
    const key = `${state.category.id}:${item.drawable}`;
    state.itemTextures[key] = texture;
  }

  function buildThumbKey(categoryId, drawable, texture) {
    return `${state.gender}:${categoryId}:${drawable}:${texture ?? 0}`;
  }

  function applyThumbToCard(card, key, src) {
    if (!src) return;
    state.thumbCache[key] = src;
    const img = card.querySelector('.preview-img');
    if (img) {
      img.src = src;
      img.classList.add('loaded');
    }
  }

  function setupThumbObserver() {
    if (thumbObserver) thumbObserver.disconnect();
    thumbObserver = new IntersectionObserver((entries) => {
      const pending = [];
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        const card = entry.target;
        const drawable = Number(card.dataset.drawable);
        const item = state.items.find((i) => i.drawable === drawable);
        if (!item || !state.category) return;

        const texture = itemTexture(item);
        const key = item.thumbKey || buildThumbKey(state.category.id, drawable, texture);
        if (state.thumbCache[key]) {
          applyThumbToCard(card, key, state.thumbCache[key]);
          return;
        }

        pending.push({
          categoryId: state.category.id,
          drawable,
          texture,
          key,
        });
      });

      if (pending.length) {
        nui('requestThumbnails', { items: pending.map(({ categoryId, drawable, texture }) => ({ categoryId, drawable, texture })) });
      }
    }, { root: itemsGrid, rootMargin: '80px', threshold: 0.05 });

    itemsGrid.querySelectorAll('.item-card').forEach((card) => thumbObserver.observe(card));
  }

  function cycleTexture(item, card) {
    const max = Math.max(1, item.textureCount || 1);
    const current = itemTexture(item);
    const next = (current + 1) % max;
    setItemTexture(item, next);
    item.texture = next;

    const texBtn = card.querySelector('.tex-btn');
    if (texBtn) texBtn.textContent = max > 1 ? `${next + 1}/${max}` : '▾';

    nui('previewItem', {
      categoryId: state.category.id,
      drawable: item.drawable,
      texture: next,
    }).then((res) => {
      if (res && typeof res.changes === 'number') applyOutfitInfo(res);
      else refreshOutfitPrice();
    });

    const key = buildThumbKey(state.category.id, item.drawable, next);
    card.dataset.thumbKey = key;
    const img = card.querySelector('.preview-img');
    if (state.thumbCache[key]) {
      applyThumbToCard(card, key, state.thumbCache[key]);
    } else if (img) {
      img.classList.remove('loaded');
      img.removeAttribute('src');
      nui('requestThumbnails', { items: [{ categoryId: state.category.id, drawable: item.drawable, texture: next }] });
    }
  }

  const payState = {
    step: 'method',
    cards: [],
    sel: null,
    pin: '',
    amount: 0,
    hasBank: false,
  };

  function nui(name, data) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data || {}),
    }).then((r) => r.json());
  }

  function showToast(msg, type) {
    toast.textContent = msg;
    toast.className = 'toast ' + (type || 'ok');
    toast.classList.remove('hidden');
    setTimeout(() => toast.classList.add('hidden'), 2800);
  }

  function favKey(catId, drawable) {
    return `${catId}:${drawable}`;
  }

  function isFav(catId, drawable) {
    return state.favorites.includes(favKey(catId, drawable));
  }

  function toggleFav(catId, drawable) {
    const k = favKey(catId, drawable);
    const i = state.favorites.indexOf(k);
    if (i >= 0) state.favorites.splice(i, 1);
    else state.favorites.push(k);
    localStorage.setItem('acardia_clothing_fav', JSON.stringify(state.favorites));
  }

  function updateOutfitFooter() {
    const btn = $('#btnBuyOutfit');
    if (state.outfitChanges < 1) {
      outfitPriceLabel.textContent = 'Aucun changement';
      btn.classList.add('disabled');
    } else {
      outfitPriceLabel.textContent = `${state.outfitChanges} piece${state.outfitChanges > 1 ? 's' : ''} — $${state.outfitPrice}`;
      btn.classList.remove('disabled');
    }
  }

  function applyOutfitInfo(info) {
    state.outfitChanges = (info && info.changes) || 0;
    state.outfitPrice = (info && info.price) || 0;
    updateOutfitFooter();
  }

  async function refreshOutfitPrice() {
    try {
      const res = await nui('getOutfitPrice');
      applyOutfitInfo(res);
    } catch (_) {
      applyOutfitInfo({ changes: 0, price: 0 });
    }
  }

  function closePayModal(result) {
    payModal.classList.add('hidden');
    if (payResolve) {
      const resolve = payResolve;
      payResolve = null;
      resolve(result || null);
    }
  }

  function drawPayStep() {
    const step = payState.step;

    if (step === 'method') {
      payBody.innerHTML = `
        <div class="pay-methods">
          <div class="pay-method" id="payCash">
            <div class="pay-method-icon">💵</div>
            <div class="pay-method-info">
              <div class="pay-method-title">Especes</div>
              <div class="pay-method-desc">Payer en liquide</div>
            </div>
          </div>
          <div class="pay-method" id="payBank">
            <div class="pay-method-icon">🏦</div>
            <div class="pay-method-info">
              <div class="pay-method-title">Compte bancaire</div>
              <div class="pay-method-desc">Debit direct Acardia Bank</div>
            </div>
          </div>
          <div class="pay-method" id="payCard">
            <div class="pay-method-icon">💳</div>
            <div class="pay-method-info">
              <div class="pay-method-title">Carte bancaire</div>
              <div class="pay-method-desc">Payer avec carte + PIN</div>
            </div>
          </div>
        </div>`;

      $('#payCash').addEventListener('click', () => closePayModal({ paymentMethod: 'cash' }));

      $('#payBank').addEventListener('click', () => {
        if (!payState.hasBank) {
          showToast('Aucun compte bancaire', 'err');
          return;
        }
        closePayModal({ paymentMethod: 'bank' });
      });

      $('#payCard').addEventListener('click', () => {
        if (!payState.cards.length) {
          showToast('Aucune carte disponible', 'err');
          return;
        }
        if (payState.cards.length === 1) {
          payState.sel = payState.cards[0];
          payState.pin = '';
          payState.step = 'pin';
          drawPayStep();
          return;
        }
        payState.step = 'selectCard';
        drawPayStep();
      });
      return;
    }

    if (step === 'selectCard') {
      payBody.innerHTML = `
        <button type="button" class="pay-back" id="payBackCards">← Retour</button>
        <div class="pay-section-title">Selectionnez votre carte</div>
        <div class="pay-cards" id="payCards"></div>`;

      const list = $('#payCards');
      payState.cards.forEach((c) => {
        const el = document.createElement('div');
        el.className = 'pay-card-item';
        el.innerHTML = `
          <div class="pay-card-num">${c.masked || '**** **** **** ****'}</div>
          <div class="pay-card-name">${c.firstname || ''} ${c.lastname || ''}</div>`;
        el.addEventListener('click', () => {
          payState.sel = c;
          payState.pin = '';
          payState.step = 'pin';
          drawPayStep();
        });
        list.appendChild(el);
      });

      $('#payBackCards').addEventListener('click', () => {
        payState.step = 'method';
        drawPayStep();
      });
      return;
    }

    if (step === 'pin') {
      const c = payState.sel;
      payState.pin = '';
      payBody.innerHTML = `
        <button type="button" class="pay-back" id="payBackPin">← Retour</button>
        <div class="pay-card-item" style="margin-bottom:16px;cursor:default">
          <div class="pay-card-num">${c.masked || '**** **** **** ****'}</div>
          <div class="pay-card-name">${c.firstname || ''} ${c.lastname || ''}</div>
        </div>
        <div class="pay-pin-label">Entrez votre code PIN</div>
        <div class="pay-pin-dots" id="payDots">
          <div class="pay-pin-dot"></div>
          <div class="pay-pin-dot"></div>
          <div class="pay-pin-dot"></div>
          <div class="pay-pin-dot"></div>
        </div>
        <div class="pay-numpad" id="payPad"></div>`;

      const dots = payBody.querySelectorAll('#payDots .pay-pin-dot');
      const pad = $('#payPad');

      function updPin() {
        dots.forEach((d, i) => d.classList.toggle('filled', i < payState.pin.length));
      }

      function addKey(lbl, cls) {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'pay-key' + (cls ? ' ' + cls : '');
        btn.textContent = lbl;
        btn.addEventListener('click', () => {
          if (lbl === '✕') {
            payState.pin = '';
            updPin();
            return;
          }
          if (lbl === 'OK') {
            if (payState.pin.length === 4) {
              closePayModal({
                paymentMethod: 'card',
                cardId: payState.sel.cardId || payState.sel.id,
                cardPin: payState.pin,
              });
            }
            return;
          }
          if (payState.pin.length < 4) {
            payState.pin += lbl;
            updPin();
          }
        });
        pad.appendChild(btn);
      }

      for (let i = 1; i <= 9; i++) addKey(String(i));
      addKey('✕', 'pay-key-clear');
      addKey('0');
      addKey('OK', 'pay-key-ok');

      $('#payBackPin').addEventListener('click', () => {
        payState.step = payState.cards.length > 1 ? 'selectCard' : 'method';
        drawPayStep();
      });
    }
  }

  async function openPaymentModal(amount, title) {
    const payInfo = await nui('getPayCards');
    const cards = (payInfo && payInfo.cards) || payInfo || [];
    const usable = (Array.isArray(cards) ? cards : []).filter((c) => !c.stolen && !c.disabled && (c.can_payment === undefined || c.can_payment === true || c.can_payment === 1));

    payState.step = 'method';
    payState.cards = usable;
    payState.sel = null;
    payState.pin = '';
    payState.amount = amount;
    payState.hasBank = !!(payInfo && payInfo.hasBank);

    payTitle.textContent = title || 'Paiement';
    payAmount.textContent = '$' + amount;
    payModal.classList.remove('hidden');
    drawPayStep();

    return new Promise((resolve) => {
      payResolve = resolve;
    });
  }

  async function purchaseWithPayment(amount, title, callbackName, extra) {
    const payment = await openPaymentModal(amount, title);
    if (!payment) return null;
    return nui(callbackName, { ...payment, ...(extra || {}) });
  }

  function renderSidebar() {
    catSidebar.innerHTML = '';
    state.categories.forEach((cat) => {
      const btn = document.createElement('button');
      btn.className = 'cat-btn' + (state.category && state.category.id === cat.id ? ' active' : '');
      btn.innerHTML = ICONS[cat.icon] || ICONS.shirt;
      btn.title = cat.label;
      btn.addEventListener('click', () => selectCategory(cat.id));
      catSidebar.appendChild(btn);
    });
  }

  function getFilteredItems() {
    let items = state.items;
    const q = searchInput.value.trim();
    if (q) {
      const num = parseInt(q.replace('#', ''), 10);
      if (!isNaN(num)) items = items.filter((i) => i.drawable === num);
      else items = items.filter((i) => String(i.drawable).includes(q));
    }
    if (state.favFilter && state.category) {
      items = items.filter((i) => isFav(state.category.id, i.drawable));
    }
    return items;
  }

  function renderGrid() {
    const items = getFilteredItems();
    catCount.textContent = `${items.length} article${items.length > 1 ? 's' : ''}`;
    itemsGrid.innerHTML = '';

    if (items.length === 0) {
      itemsGrid.innerHTML = '<p style="grid-column:1/-1;text-align:center;color:var(--muted);padding:40px 0;font-size:13px">Aucun article</p>';
      return;
    }

    const catIcon = ICONS[state.category.icon] || ICONS.shirt;
    const frag = document.createDocumentFragment();

    items.forEach((item) => {
      const el = document.createElement('div');
      const sel = state.selected && state.selected.drawable === item.drawable;
      const texture = itemTexture(item);
      const texCount = Math.max(1, item.textureCount || 1);
      const thumbKey = item.thumbKey || buildThumbKey(state.category.id, item.drawable, texture);
      const src = state.thumbCache[thumbKey] || item.image || null;
      el.className = 'item-card' + (sel ? ' selected' : '');
      el.dataset.drawable = item.drawable;
      el.dataset.thumbKey = thumbKey;
      el.innerHTML = `
        <span class="price">$${item.price || state.prices.item}</span>
        <button type="button" class="tex-btn" title="Variante couleur">${texCount > 1 ? `${texture + 1}/${texCount}` : '▾'}</button>
        <button type="button" class="fav ${isFav(state.category.id, item.drawable) ? 'on' : ''}">♥</button>
        <div class="preview">
          <img class="preview-img${src ? ' loaded' : ''}" ${src ? `src="${src}"` : ''} alt="" loading="lazy"/>
          <div class="preview-fallback">${catIcon}</div>
        </div>
        <span class="num">#${item.drawable}</span>
      `;

      el.querySelector('.fav').addEventListener('click', (e) => {
        e.stopPropagation();
        toggleFav(state.category.id, item.drawable);
        el.querySelector('.fav').classList.toggle('on', isFav(state.category.id, item.drawable));
      });

      el.querySelector('.tex-btn').addEventListener('click', (e) => {
        e.stopPropagation();
        if (texCount <= 1) return;
        cycleTexture(item, el);
      });

      el.addEventListener('click', async () => {
        state.selected = { ...item, texture: itemTexture(item) };
        itemsGrid.querySelectorAll('.item-card.selected').forEach((c) => c.classList.remove('selected'));
        el.classList.add('selected');
        try {
          const res = await nui('previewItem', {
            categoryId: state.category.id,
            drawable: item.drawable,
            texture: itemTexture(item),
          });
          if (res && typeof res.changes === 'number') applyOutfitInfo(res);
          else refreshOutfitPrice();
        } catch (_) {
          refreshOutfitPrice();
        }
      });

      const imgEl = el.querySelector('.preview-img');
      if (imgEl) {
        imgEl.addEventListener('error', () => {
          imgEl.classList.remove('loaded');
          imgEl.removeAttribute('src');
          if (state.thumbCache[thumbKey]) delete state.thumbCache[thumbKey];
        }, { once: true });
        if (src) {
          imgEl.addEventListener('load', () => {
            imgEl.classList.add('loaded');
            state.thumbCache[thumbKey] = src;
          }, { once: true });
        }
      }
      frag.appendChild(el);
    });

    itemsGrid.appendChild(frag);
    setupThumbObserver();
  }

  async function selectCategory(id) {
    const res = await nui('selectCategory', { categoryId: id });
    if (!res || !res.ok) return;
    state.category = res.category;
    state.items = res.items || [];
    if (res.gender) state.gender = res.gender;
    state.selected = null;
    catTitle.textContent = state.category.label;
    $('#headerIcon').innerHTML = ICONS[state.category.icon] || ICONS.shirt;
    searchInput.value = '';
    renderSidebar();
    renderGrid();
    refreshOutfitPrice();
  }

  function setRotateVisible(show) {
    rotateZone.classList.toggle('hidden', !show);
  }

  function doRotate(delta) {
    nui('rotate', { delta });
  }

  function setView(view) {
    nui('rotate', { view });
  }

  rotateZone.addEventListener('mousedown', (e) => {
    if (e.button !== 0) return;
    dragging = true;
    lastMouseX = e.clientX;
    rotateZone.classList.add('dragging');
  });

  window.addEventListener('mousemove', (e) => {
    if (!dragging) return;
    const dx = e.clientX - lastMouseX;
    lastMouseX = e.clientX;
    if (Math.abs(dx) > 0) doRotate(dx * 0.4);
  });

  window.addEventListener('mouseup', () => {
    dragging = false;
    rotateZone.classList.remove('dragging');
  });

  rotateZone.querySelectorAll('[data-view]').forEach((btn) => {
    btn.addEventListener('click', () => setView(btn.dataset.view));
  });

  $('#rotLeft').addEventListener('click', () => doRotate(-15));
  $('#rotRight').addEventListener('click', () => doRotate(15));

  function open(msg) {
    state.categories = msg.categories || [];
    state.category = msg.category;
    state.items = msg.items || [];
    state.gender = msg.gender || state.gender;
    state.prices = msg.prices || state.prices;
    state.selected = null;
    state.outfitChanges = 0;
    state.outfitPrice = 0;

    root.classList.remove('hidden');
    setRotateVisible(true);
    catTitle.textContent = state.category.label;
    $('#headerIcon').innerHTML = ICONS[state.category.icon] || ICONS.shirt;
    $('#hangerPrice').textContent = '$' + state.prices.hanger;
    singlePriceLabel.textContent = '$' + state.prices.item;
    updateOutfitFooter();
    renderSidebar();
    renderGrid();
    refreshOutfitPrice();
  }

  function close() {
    root.classList.add('hidden');
    setRotateVisible(false);
    payModal.classList.add('hidden');
    nui('close');
  }

  $('#btnClose').addEventListener('click', close);
  $('#payClose').addEventListener('click', () => closePayModal(null));
  searchInput.addEventListener('input', renderGrid);

  $('#btnFavFilter').addEventListener('click', () => {
    state.favFilter = !state.favFilter;
    $('#btnFavFilter').classList.toggle('active', state.favFilter);
    renderGrid();
  });

  $('#btnReset').addEventListener('click', async () => {
    try {
      const res = await nui('resetLook');
      applyOutfitInfo(res || { changes: 0, price: 0 });
    } catch (_) {
      applyOutfitInfo({ changes: 0, price: 0 });
    }
    state.selected = null;
    if (state.category) selectCategory(state.category.id);
  });

  $('#btnBuySingle').addEventListener('click', async () => {
    if (!state.selected) {
      showToast('Selectionnez un article', 'err');
      return;
    }
    const res = await purchaseWithPayment(state.prices.item, 'Achat unique', 'buySingle');
    if (!res) return;
    if (res.ok) {
      showToast('Achat effectue ! Item ajoute a l inventaire', 'ok');
      if (typeof res.changes === 'number') applyOutfitInfo(res);
      else refreshOutfitPrice();
    } else {
      showToast((res && res.msg) || 'Erreur', 'err');
    }
  });

  $('#btnHanger').addEventListener('click', async () => {
    if (!state.selected) {
      showToast('Selectionnez un article', 'err');
      return;
    }
    const res = await purchaseWithPayment(state.prices.hanger, 'Ceintre', 'buyHanger');
    if (!res) return;
    showToast(res.ok ? (res.msg || 'Ceintre ajoute !') : ((res && res.msg) || 'Erreur'), res.ok ? 'ok' : 'err');
  });

  let nameModalMode = 'save'; // 'save' | 'buy'

  function openNameModal(mode, title) {
    nameModalMode = mode || 'save';
    $('#nameModalTitle').textContent = title || 'Nom de la tenue';
    $('#confirmOutfit').textContent = mode === 'buy' ? 'Acheter' : 'Enregistrer';
    $('#nameModal').classList.remove('hidden');
    $('#outfitName').value = '';
    setTimeout(() => $('#outfitName').focus(), 50);
  }

  $('#btnBuyOutfit').addEventListener('click', () => {
    if (state.outfitChanges < 1) {
      showToast('Selectionnez au moins un article', 'err');
      return;
    }
    openNameModal('buy', 'Nom de la tenue complete');
  });

  $('#btnSaveOutfit').addEventListener('click', () => {
    openNameModal('save', 'Enregistrer la tenue');
  });

  $('#cancelOutfit').addEventListener('click', () => {
    $('#nameModal').classList.add('hidden');
  });

  $('#confirmOutfit').addEventListener('click', async () => {
    const name = ($('#outfitName').value || '').trim() || 'Tenue';
    $('#nameModal').classList.add('hidden');

    if (nameModalMode === 'buy') {
      try {
        const res = await purchaseWithPayment(state.outfitPrice, 'Tenue complete', 'buyOutfit', { outfitName: name });
        if (!res) return;
        if (res.ok) {
          showToast(`Tenue "${name}" achetee — $${res.price || state.outfitPrice}`, 'ok');
          applyOutfitInfo({ changes: 0, price: 0 });
        } else {
          showToast((res && res.msg) || 'Erreur', 'err');
        }
      } catch (e) {
        showToast('Erreur paiement', 'err');
      }
      return;
    }

    try {
      const res = await nui('saveOutfit', { name });
      showToast(res && res.ok ? 'Tenue enregistree !' : ((res && res.msg) || 'Erreur'), res && res.ok ? 'ok' : 'err');
      if (res && res.ok) refreshOutfitPrice();
    } catch (_) {
      showToast('Erreur', 'err');
    }
  });

  $('#btnOutfits').addEventListener('click', async () => {
    const outfits = await nui('getOutfits');
    const list = $('#outfitList');
    list.innerHTML = '';
    if (!outfits || !outfits.length) {
      list.innerHTML = '<p style="color:var(--muted);font-size:13px">Aucune tenue sauvegardee</p>';
    } else {
      outfits.forEach((o) => {
        const el = document.createElement('div');
        el.className = 'outfit-item';
        el.textContent = o.name || o.outfitname || 'Tenue';
        list.appendChild(el);
      });
    }
    $('#outfitModal').classList.remove('hidden');
  });

  $('#closeOutfits').addEventListener('click', () => $('#outfitModal').classList.add('hidden'));

  document.addEventListener('keydown', (e) => {
    if (root.classList.contains('hidden')) return;
    const typing = document.activeElement === searchInput || document.activeElement === $('#outfitName');
    if (!typing && (e.key === 'q' || e.key === 'Q' || e.key === 'ArrowLeft')) {
      doRotate(-12);
      e.preventDefault();
      return;
    }
    if (!typing && (e.key === 'd' || e.key === 'D' || e.key === 'ArrowRight')) {
      doRotate(12);
      e.preventDefault();
      return;
    }
    if (e.key === 'Escape') {
      if (!payModal.classList.contains('hidden')) {
        closePayModal(null);
        return;
      }
      if (!$('#nameModal').classList.contains('hidden')) {
        $('#nameModal').classList.add('hidden');
        return;
      }
      if (!$('#outfitModal').classList.contains('hidden')) {
        $('#outfitModal').classList.add('hidden');
        return;
      }
      close();
    }
  });

  window.addEventListener('message', (e) => {
    const msg = e.data;
    if (msg.action === 'open') open(msg);
    if (msg.action === 'close') {
      root.classList.add('hidden');
      setRotateVisible(false);
      payModal.classList.add('hidden');
    }
    if (msg.action === 'thumbnails' && msg.images) {
      Object.entries(msg.images).forEach(([key, src]) => {
        state.thumbCache[key] = src;
        itemsGrid.querySelectorAll('.item-card').forEach((card) => {
          if (card.dataset.thumbKey === key) applyThumbToCard(card, key, src);
        });
      });
    }
  });
})();
