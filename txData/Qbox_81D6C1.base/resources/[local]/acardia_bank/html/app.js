(() => {
'use strict';

const $ = s => document.querySelector(s);
const $$ = s => [...document.querySelectorAll(s)];
const root = $('#root');
const tablet = $('#tablet');
const atm = $('#atm');
const resName = window.GetParentResourceName ? window.GetParentResourceName() : 'acardia_bank';

const state = {
  view: 'home',
  data: null,
  accountDetail: null,
  selectedCard: null,
  atmStep: 'cards',
  atmSession: null,
  modalCb: null,
};

function money(n) {
  return '$' + (Number(n) || 0).toLocaleString('en-US');
}

function nui(event, body) {
  return fetch(`https://${resName}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body || {}),
  }).then(r => {
    const ct = r.headers.get('content-type') || '';
    if (ct.includes('application/json')) return r.json();
    return r.text().then(t => { try { return JSON.parse(t); } catch { return t; } });
  }).then(res => {
    if (res && typeof res === 'object' && 'ok' in res) return [res.ok, res.result];
    return res;
  }).catch(() => null);
}

function toast(msg, type) {
  const el = document.createElement('div');
  el.className = 'toast ' + (type || 'success');
  el.textContent = msg;
  document.body.appendChild(el);
  setTimeout(() => { el.style.opacity = '0'; setTimeout(() => el.remove(), 300); }, 3000);
}

/* ══════════ SIDEBAR NAV ══════════ */
$$('.sb-nav li').forEach(li => {
  li.addEventListener('click', () => {
    const nav = li.dataset.nav;
    if (nav === 'catalog' && state.data && !state.data.canCreate) {
      toast('Rendez-vous à la Pacific Standard Bank pour ouvrir un compte', 'error');
      return;
    }
    state.view = nav;
    state.accountDetail = null;
    state.selectedCard = null;
    render();
  });
});

function setActiveNav(view) {
  $$('.sb-nav li').forEach(li => {
    li.classList.toggle('active', li.dataset.nav === view);
  });
}

/* ══════════ AMOUNT MODAL ══════════ */
const modal = $('#amountModal');
const modalAmount = $('#modalAmount');
const modalError = $('#modalError');
const presets = [100, 500, 1000, 5000, 10000];

function openModal(title, sub, max, cb) {
  $('#modalTitle').textContent = title;
  $('#modalSub').textContent = sub || '';
  modalAmount.value = '';
  modalAmount.max = max || 999999999;
  modalError.classList.add('hidden');
  state.modalCb = cb;

  const presetsEl = $('#modalPresets');
  presetsEl.innerHTML = '';
  const presetValues = max ? presets.filter(v => v <= max) : presets;
  presetValues.forEach(v => {
    const btn = document.createElement('button');
    btn.textContent = money(v);
    btn.addEventListener('click', () => {
      $$('#modalPresets button').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      modalAmount.value = v;
      modalError.classList.add('hidden');
    });
    presetsEl.appendChild(btn);
  });
  if (max) {
    const allBtn = document.createElement('button');
    allBtn.textContent = 'Tout';
    allBtn.addEventListener('click', () => {
      $$('#modalPresets button').forEach(b => b.classList.remove('selected'));
      allBtn.classList.add('selected');
      modalAmount.value = max;
      modalError.classList.add('hidden');
    });
    presetsEl.appendChild(allBtn);
  }

  modal.classList.remove('hidden');
}

$('#modalConfirm').addEventListener('click', () => {
  const val = Math.floor(Number(modalAmount.value) || 0);
  if (val < 1) {
    modalError.textContent = 'Entrez un montant valide';
    modalError.classList.remove('hidden');
    return;
  }
  const max = Number(modalAmount.max) || 999999999;
  if (val > max) {
    modalError.textContent = `Montant maximum : ${money(max)}`;
    modalError.classList.remove('hidden');
    return;
  }
  modal.classList.add('hidden');
  if (state.modalCb) state.modalCb(val);
});
$('#modalCancel').addEventListener('click', () => modal.classList.add('hidden'));

/* ══════════ RENDER ROUTER ══════════ */
function render() {
  const view = state.view;
  setActiveNav(view);

  const backBtn = $('#btnBack');
  const needsBack = ['accountDetail', 'newCard', 'cardDetail'].includes(view);
  backBtn.classList.toggle('hidden', !needsBack);

  switch (view) {
    case 'home': renderHome(); break;
    case 'accounts': renderAccounts(); break;
    case 'accountDetail': renderAccountDetail(); break;
    case 'cards': renderCards(); break;
    case 'newCard': renderNewCard(); break;
    case 'cardDetail': renderCardDetail(); break;
    case 'transfer': renderTransfer(); break;
    case 'history': renderHistory(); break;
    case 'catalog': renderCatalog(); break;
    case 'company': renderCompany(); break;
    default: renderHome();
  }
}

$('#btnBack').addEventListener('click', () => {
  if (state.view === 'accountDetail') { state.view = 'accounts'; }
  else if (state.view === 'newCard' || state.view === 'cardDetail') { state.view = 'cards'; }
  else if (state.view === 'company') { state.view = 'catalog'; }
  else { state.view = 'home'; }
  render();
});

/* ══════════ HOME ══════════ */
function renderHome() {
  const d = state.data;
  if (!d) return;
  const totalBalance = (d.accounts || []).reduce((s, a) => s + a.balance, 0);
  const totalCards = (d.accounts || []).reduce((s, a) => s + a.activeCards, 0);
  const numAccounts = (d.accounts || []).length;

  $('#screenTitle').textContent = `Bonjour, ${d.firstname}`;
  $('#screenSub').textContent = 'Bienvenue sur votre espace bancaire Acardia';
  $('#cashLabel').textContent = money(d.cash);

  const v = $('#tabletView');
  v.innerHTML = `
    <div class="dash-hero">
      <div class="dash-card">
        <div class="dc-label">Solde total</div>
        <div class="dc-value">${money(totalBalance)}</div>
        <div class="dc-sub">${numAccounts} compte${numAccounts > 1 ? 's' : ''} actif${numAccounts > 1 ? 's' : ''}</div>
      </div>
      <div class="dash-card">
        <div class="dc-label">Liquide</div>
        <div class="dc-value">${money(d.cash)}</div>
        <div class="dc-sub">En poche</div>
      </div>
      <div class="dash-card">
        <div class="dc-label">Cartes actives</div>
        <div class="dc-value">${totalCards}</div>
        <div class="dc-sub">Sur tous vos comptes</div>
      </div>
    </div>
    <div class="quick-actions">
      <button class="qa-btn primary" data-qa="accounts">Mes comptes</button>
      <button class="qa-btn" data-qa="cards">Mes cartes</button>
      <button class="qa-btn" data-qa="transfer">Virement</button>
      <button class="qa-btn" data-qa="history">Historique</button>
      ${d.canCreate ? '<button class="qa-btn" data-qa="catalog">Ouvrir un compte</button>' : ''}
    </div>
  `;

  v.querySelectorAll('[data-qa]').forEach(btn => {
    btn.addEventListener('click', () => { state.view = btn.dataset.qa; render(); });
  });
}

/* ══════════ ACCOUNTS LIST ══════════ */
function renderAccounts() {
  const d = state.data;
  $('#screenTitle').textContent = 'Mes comptes';
  $('#screenSub').textContent = '';
  const v = $('#tabletView');

  if (!d || !d.accounts || d.accounts.length === 0) {
    v.innerHTML = `<div class="empty-state">
      <div class="es-icon">🏦</div>
      <div class="es-title">Aucun compte</div>
      <div class="es-sub">Rendez-vous à la Pacific Standard Bank pour ouvrir votre premier compte.</div>
    </div>`;
    return;
  }

  v.innerHTML = '<div class="acc-grid"></div>';
  const grid = v.querySelector('.acc-grid');
  d.accounts.forEach(acc => {
    const el = document.createElement('div');
    el.className = 'acc-item';
    el.innerHTML = `
      <div class="ai-type">${acc.type === 'business' ? 'Entreprise' : 'Personnel'}</div>
      <div class="ai-label">${acc.label}</div>
      <div class="ai-balance">${money(acc.balance)}</div>
      <div class="ai-iban">${acc.iban}</div>
      <div class="ai-meta">
        <span>Plafond : ${money(acc.ceiling)}</span>
        <span>Cartes : ${acc.activeCards}/${acc.maxCards}</span>
      </div>
    `;
    el.addEventListener('click', () => openAccountDetail(acc.id));
    grid.appendChild(el);
  });
}

async function openAccountDetail(accountId) {
  const res = await nui('accountDetails', { accountId });
  if (!res) { toast('Erreur de chargement', 'error'); return; }
  state.accountDetail = res;
  state.data.cash = res.cash;
  $('#cashLabel').textContent = money(res.cash);
  state.view = 'accountDetail';
  render();
}

/* ══════════ ACCOUNT DETAIL ══════════ */
function renderAccountDetail() {
  const d = state.accountDetail;
  if (!d) return;
  const acc = d.account;
  $('#screenTitle').textContent = acc.label;
  $('#screenSub').textContent = acc.iban;
  const v = $('#tabletView');

  v.innerHTML = `
    <div class="ad-top">
      <div class="ad-balance-box">
        <div class="ab-label">Solde disponible</div>
        <div class="ab-amount">${money(acc.balance)}</div>
        <div class="ab-info">Plafond : ${money(acc.ceiling)} · ${acc.activeCards}/${acc.maxCards} carte(s)</div>
        <div class="ad-actions">
          <button class="btn btn-primary" id="adDeposit">Déposer</button>
          <button class="btn btn-primary" id="adWithdraw">Retirer</button>
          <button class="btn btn-ghost" id="adTransfer">Virement</button>
        </div>
      </div>
      <div class="ad-info-box">
        <div class="info-row"><span class="info-label">Type</span><span class="info-val">${acc.type === 'business' ? 'Entreprise' : 'Personnel'}</span></div>
        <div class="info-row"><span class="info-label">IBAN</span><span class="info-val" style="font-family:monospace;font-size:11px">${acc.iban}</span></div>
        <div class="info-row"><span class="info-label">Plafond</span><span class="info-val">${money(acc.ceiling)}</span></div>
        <div class="info-row"><span class="info-label">Cartes</span><span class="info-val">${acc.activeCards}/${acc.maxCards}</span></div>
        ${acc.companyName ? `<div class="info-row"><span class="info-label">Entreprise</span><span class="info-val">${acc.companyName}</span></div>` : ''}
      </div>
    </div>
    <h3 style="font-size:15px;font-weight:700;margin-bottom:12px">Dernières transactions</h3>
    <div class="history-list" id="adHistory"></div>
  `;

  renderHistoryRows($('#adHistory'), d.history || []);

  $('#adDeposit').addEventListener('click', () => {
    const maxDeposit = acc.ceiling - acc.balance;
    const maxCash = state.data.cash;
    const max = Math.min(maxDeposit, maxCash);
    openModal('Déposer', `Liquide : ${money(maxCash)} · Disponible : ${money(maxDeposit)}`, max, async (amount) => {
      const [ok, result] = await nui('deposit', { accountId: acc.id, amount });
      if (ok === false || (result && result === false)) { toast(typeof result === 'string' ? result : 'Erreur', 'error'); return; }
      if (result && result.account) {
        state.accountDetail = result;
        state.data.cash = result.cash;
        updateAccountInList(result.account);
        toast(`${money(amount)} déposé`, 'success');
        render();
      }
    });
  });

  $('#adWithdraw').addEventListener('click', () => {
    openModal('Retirer', `Solde : ${money(acc.balance)}`, acc.balance, async (amount) => {
      const [ok, result] = await nui('withdraw', { accountId: acc.id, amount });
      if (ok === false || (result && result === false)) { toast(typeof result === 'string' ? result : 'Erreur', 'error'); return; }
      if (result && result.account) {
        state.accountDetail = result;
        state.data.cash = result.cash;
        updateAccountInList(result.account);
        toast(`${money(amount)} retiré`, 'success');
        render();
      }
    });
  });

  $('#adTransfer').addEventListener('click', () => {
    state.view = 'transfer';
    render();
  });
}

function updateAccountInList(acc) {
  if (!state.data || !state.data.accounts) return;
  for (let i = 0; i < state.data.accounts.length; i++) {
    if (state.data.accounts[i].id === acc.id) {
      state.data.accounts[i] = acc;
      break;
    }
  }
  $('#cashLabel').textContent = money(state.data.cash);
}

/* ══════════ CARDS ══════════ */
function renderCards() {
  $('#screenTitle').textContent = 'Mes cartes';
  $('#screenSub').textContent = '';
  const v = $('#tabletView');
  const d = state.data;
  if (!d || !d.accounts || d.accounts.length === 0) {
    v.innerHTML = `<div class="empty-state"><div class="es-icon">💳</div><div class="es-title">Aucune carte</div><div class="es-sub">Ouvrez un compte pour créer votre première carte.</div></div>`;
    return;
  }

  v.innerHTML = '<div class="cards-grid" id="cardsGrid"></div>';
  const grid = $('#cardsGrid');

  let hasCards = false;
  d.accounts.forEach(acc => {
    if (!state.accountDetail || state.accountDetail.account.id !== acc.id) {
      nui('accountDetails', { accountId: acc.id }).then(res => {
        if (res && res.cards) {
          renderCardItems(grid, res.cards, acc, res);
          if (res.cards.length > 0) hasCards = true;
        }
      });
    } else {
      const cards = state.accountDetail.cards || [];
      renderCardItems(grid, cards, acc, state.accountDetail);
      if (cards.length > 0) hasCards = true;
    }
  });

  const addBtnWrap = document.createElement('div');
  addBtnWrap.style.cssText = 'margin-top:16px;';
  addBtnWrap.innerHTML = `<button class="btn btn-primary" id="btnNewCard">+ Nouvelle carte</button>`;
  v.appendChild(addBtnWrap);
  $('#btnNewCard').addEventListener('click', () => { state.view = 'newCard'; render(); });
}

function renderCardItems(grid, cards, acc, detail) {
  cards.filter(c => !c.stolen && !c.disabled).forEach(card => {
    const status = 'active';
    const statusLabel = card.stolen ? 'Volée' : card.disabled ? 'Désactivée' : 'Active';
    const el = document.createElement('div');
    el.innerHTML = `
      <div class="card-plastic">
        <div>
          <div class="cp-brand">Acardia Bank</div>
          <div class="cp-chip"></div>
        </div>
        <div class="cp-number">${card.masked}</div>
        <div class="cp-bottom">
          <div class="cp-holder">${card.firstname} ${card.lastname}</div>
          <div class="cp-status ${status}">${statusLabel}</div>
        </div>
      </div>
    `;
    el.style.cursor = 'pointer';
    el.addEventListener('click', () => {
      state.selectedCard = { card, account: acc, detail };
      state.view = 'cardDetail';
      render();
    });
    grid.appendChild(el);
  });
}

/* ══════════ CARD DETAIL ══════════ */
function renderCardDetail() {
  const sel = state.selectedCard;
  if (!sel) return;
  const card = sel.card;
  $('#screenTitle').textContent = `Carte **** ${card.masked.slice(-4)}`;
  $('#screenSub').textContent = `${card.firstname} ${card.lastname}`;
  const v = $('#tabletView');
  const status = card.stolen ? 'stolen' : card.disabled ? 'disabled' : 'active';
  const statusLabel = card.stolen ? 'Volée' : card.disabled ? 'Désactivée' : 'Active';

  v.innerHTML = `
    <div class="card-plastic" style="max-width:360px;margin-bottom:20px">
      <div><div class="cp-brand">Acardia Bank</div><div class="cp-chip"></div></div>
      <div class="cp-number">${card.masked}</div>
      <div class="cp-bottom">
        <div class="cp-holder">${card.firstname} ${card.lastname}</div>
        <div class="cp-status ${status}">${statusLabel}</div>
      </div>
    </div>
    <div class="card-detail">
      <div class="card-toggles">
        <div class="card-toggle">
          <label>Transactions</label>
          <label class="toggle-switch"><input type="checkbox" data-perm="canTransaction" ${card.canTransaction ? 'checked' : ''} ${card.disabled ? 'disabled' : ''}><span class="slider"></span></label>
        </div>
        <div class="card-toggle">
          <label>Paiements</label>
          <label class="toggle-switch"><input type="checkbox" data-perm="canPayment" ${card.canPayment ? 'checked' : ''} ${card.disabled ? 'disabled' : ''}><span class="slider"></span></label>
        </div>
        <div class="card-toggle">
          <label>Virements</label>
          <label class="toggle-switch"><input type="checkbox" data-perm="canTransfer" ${card.canTransfer ? 'checked' : ''} ${card.disabled ? 'disabled' : ''}><span class="slider"></span></label>
        </div>
      </div>
      <div class="card-actions">
        <button class="btn btn-primary btn-sm" id="cdSave" ${card.disabled ? 'disabled' : ''}>Sauvegarder</button>
        <button class="btn btn-danger btn-sm" id="cdStolen" ${card.stolen || card.disabled ? 'disabled' : ''}>Déclarer volée</button>
        <button class="btn btn-ghost btn-sm" id="cdDelete" ${card.disabled ? 'disabled' : ''}>Supprimer</button>
      </div>
    </div>
  `;

  $('#cdSave').addEventListener('click', async () => {
    const perms = {};
    v.querySelectorAll('[data-perm]').forEach(inp => { perms[inp.dataset.perm] = inp.checked ? 1 : 0; });
    const [ok, result] = await nui('updateCard', { cardId: card.id, ...perms });
    if (!ok) { toast('Erreur', 'error'); return; }
    toast('Permissions mises à jour', 'success');
    state.accountDetail = null;
    state.selectedCard = null;
    state.view = 'cards';
    render();
  });

  $('#cdStolen').addEventListener('click', async () => {
    const [ok, result] = await nui('reportStolen', { cardId: card.id });
    if (!ok) { toast('Erreur', 'error'); return; }
    if (result && result.account) updateAccountInList(result.account);
    toast('Carte déclarée volée', 'success');
    state.view = 'cards';
    render();
  });

  $('#cdDelete').addEventListener('click', async () => {
    const [ok, result] = await nui('deleteCard', { cardId: card.id });
    if (!ok) { toast('Erreur', 'error'); return; }
    if (result && result.account) updateAccountInList(result.account);
    toast('Carte supprimée', 'success');
    state.view = 'cards';
    render();
  });
}

/* ══════════ NEW CARD ══════════ */
function renderNewCard() {
  $('#screenTitle').textContent = 'Nouvelle carte';
  $('#screenSub').textContent = '';
  const d = state.data;
  const v = $('#tabletView');

  const accs = (d.accounts || []).filter(a => a.activeCards < a.maxCards);
  if (accs.length === 0) {
    v.innerHTML = `<div class="empty-state"><div class="es-icon">🚫</div><div class="es-title">Aucun slot disponible</div><div class="es-sub">Toutes vos cartes sont utilisées. Déclarez une carte volée pour libérer un slot.</div></div>`;
    return;
  }

  v.innerHTML = `
    <form id="newCardForm" style="max-width:440px">
      <div class="form-group">
        <label>Compte</label>
        <select id="ncAccount">${accs.map(a => `<option value="${a.id}">${a.label} (${a.activeCards}/${a.maxCards})</option>`).join('')}</select>
      </div>
      <div class="form-row">
        <div class="form-group"><label>Prénom sur la carte</label><input id="ncFirst" placeholder="Prénom" maxlength="50"/></div>
        <div class="form-group"><label>Nom sur la carte</label><input id="ncLast" placeholder="Nom" maxlength="50"/></div>
      </div>
      <div class="form-group"><label>Code PIN (4 chiffres)</label><input id="ncPin" type="password" maxlength="4" placeholder="••••"/></div>
      <div class="form-row">
        <div class="form-group"><label>Transactions</label><label class="toggle-switch"><input type="checkbox" id="ncTx" checked><span class="slider"></span></label></div>
        <div class="form-group"><label>Paiements</label><label class="toggle-switch"><input type="checkbox" id="ncPay" checked><span class="slider"></span></label></div>
        <div class="form-group"><label>Virements</label><label class="toggle-switch"><input type="checkbox" id="ncTr" checked><span class="slider"></span></label></div>
      </div>
      <button class="btn btn-primary" type="submit">Créer la carte</button>
    </form>
  `;

  const char = state.data;
  if (char) {
    $('#ncFirst').value = char.firstname || '';
    $('#ncLast').value = char.lastname || '';
  }

  $('#newCardForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const pin = $('#ncPin').value;
    if (!/^\d{4}$/.test(pin)) { toast('Le code PIN doit être de 4 chiffres', 'error'); return; }
    const [ok, result] = await nui('createCard', {
      accountId: Number($('#ncAccount').value),
      firstname: $('#ncFirst').value,
      lastname: $('#ncLast').value,
      pin,
      canTransaction: $('#ncTx').checked ? 1 : 0,
      canPayment: $('#ncPay').checked ? 1 : 0,
      canTransfer: $('#ncTr').checked ? 1 : 0,
    });
    if (!ok) { toast(typeof result === 'string' ? result : 'Erreur', 'error'); return; }
    if (result && result.account) updateAccountInList(result.account);
    toast('Carte créée avec succès', 'success');
    state.view = 'cards';
    render();
  });
}

/* ══════════ TRANSFER ══════════ */
function renderTransfer() {
  $('#screenTitle').textContent = 'Virement';
  $('#screenSub').textContent = '';
  const d = state.data;
  const v = $('#tabletView');

  if (!d || !d.accounts || d.accounts.length === 0) {
    v.innerHTML = `<div class="empty-state"><div class="es-icon">🏦</div><div class="es-title">Aucun compte</div></div>`;
    return;
  }

  v.innerHTML = `
    <form id="transferForm" class="transfer-form">
      <div class="form-group">
        <label>Compte source</label>
        <select id="tfFrom">${d.accounts.map(a => `<option value="${a.id}">${a.label} — ${money(a.balance)}</option>`).join('')}</select>
      </div>
      <div class="form-group"><label>IBAN destinataire</label><input id="tfIban" placeholder="ACXXXXXXXXXX" maxlength="24"/></div>
      <div class="form-group"><label>Montant</label><input id="tfAmount" type="number" min="1" placeholder="0"/></div>
      <div class="form-group"><label>Motif (optionnel)</label><input id="tfLabel" placeholder="Motif du virement" maxlength="80"/></div>
      <button class="btn btn-primary" type="submit">Envoyer le virement</button>
    </form>
  `;

  if (state.accountDetail && state.accountDetail.account) {
    $('#tfFrom').value = state.accountDetail.account.id;
  }

  $('#transferForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const amount = Number($('#tfAmount').value);
    if (amount < 1) { toast('Montant invalide', 'error'); return; }
    const [ok, result] = await nui('transfer', {
      accountId: Number($('#tfFrom').value),
      iban: $('#tfIban').value.trim().toUpperCase(),
      amount,
      label: $('#tfLabel').value.trim() || null,
    });
    if (!ok) { toast(typeof result === 'string' ? result : 'Erreur', 'error'); return; }
    if (result && result.account) updateAccountInList(result.account);
    toast(`Virement de ${money(amount)} effectué`, 'success');
    state.view = 'accounts';
    render();
  });
}

/* ══════════ HISTORY ══════════ */
function renderHistory() {
  $('#screenTitle').textContent = 'Historique';
  $('#screenSub').textContent = '';
  const d = state.data;
  const v = $('#tabletView');

  if (!d || !d.accounts || d.accounts.length === 0) {
    v.innerHTML = `<div class="empty-state"><div class="es-icon">📋</div><div class="es-title">Aucune transaction</div></div>`;
    return;
  }

  v.innerHTML = `
    <div class="form-group" style="max-width:300px;margin-bottom:16px">
      <label>Compte</label>
      <select id="histAcc">${d.accounts.map(a => `<option value="${a.id}">${a.label}</option>`).join('')}</select>
    </div>
    <div class="history-list" id="histList"></div>
  `;

  const loadHistory = async (accId) => {
    const res = await nui('accountDetails', { accountId: accId });
    if (res && res.history) renderHistoryRows($('#histList'), res.history);
  };

  loadHistory(d.accounts[0].id);
  $('#histAcc').addEventListener('change', (e) => loadHistory(Number(e.target.value)));
}

function renderHistoryRows(container, rows) {
  if (!rows || rows.length === 0) {
    container.innerHTML = '<div class="empty-state" style="padding:24px"><div class="es-sub">Aucune transaction</div></div>';
    return;
  }
  container.innerHTML = '';
  rows.forEach(tx => {
    const isIn = ['deposit', 'atm_deposit', 'transfer_in', 'credit', 'open'].includes(tx.type);
    const isOut = ['withdraw', 'atm_withdraw', 'transfer_out', 'debit'].includes(tx.type);
    const iconClass = isIn ? 'in' : isOut ? 'out' : 'neutral';
    const icon = isIn ? '↓' : isOut ? '↑' : '•';
    const amtClass = isIn ? 'positive' : isOut ? 'negative' : '';
    const sign = isIn ? '+' : isOut ? '-' : '';
    const date = tx.created_at ? new Date(tx.created_at).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' }) : '';

    const el = document.createElement('div');
    el.className = 'tx-row';
    el.innerHTML = `
      <div class="tx-icon ${iconClass}">${icon}</div>
      <div class="tx-info"><div class="tx-label">${tx.label || tx.type}</div><div class="tx-date">${date}</div></div>
      <div class="tx-amount ${amtClass}">${sign}${money(Math.abs(tx.amount))}</div>
    `;
    container.appendChild(el);
  });
}

/* ══════════ CATALOG ══════════ */
function renderCatalog() {
  $('#screenTitle').textContent = 'Ouvrir un compte';
  $('#screenSub').textContent = 'Choisissez le type de compte qui vous convient';
  const d = state.data;
  const v = $('#tabletView');

  if (!d || !d.catalog) return;

  v.innerHTML = '<div class="cat-grid"></div>';
  const grid = v.querySelector('.cat-grid');

  const icons = ['🏦', '⭐', '👑', '🏢'];
  d.catalog.forEach((slot, i) => {
    const el = document.createElement('div');
    el.className = 'cat-card';
    let btnClass = 'open', btnText = 'Ouvrir';
    if (slot.owned) { btnClass = 'owned'; btnText = '✓ Ouvert'; }
    else if (slot.locked) { btnClass = 'locked'; btnText = 'Verrouillé'; }

    el.innerHTML = `
      <div class="cc-icon">${icons[i] || '🏦'}</div>
      <div class="cc-label">${slot.label}</div>
      <div class="cc-sub">${slot.subtitle}</div>
      <div class="cc-ceiling">${money(slot.ceiling)}</div>
      <div class="cc-cards">${slot.maxCards} carte${slot.maxCards > 1 ? 's' : ''} max</div>
      <button class="cc-btn ${btnClass}">${btnText}</button>
    `;

    if (!slot.owned && !slot.locked) {
      el.querySelector('.cc-btn').addEventListener('click', () => {
        if (slot.requiresCompany) {
          state._catalogSlot = slot.slot;
          state.view = 'company';
          render();
        } else {
          createAccount(slot.slot);
        }
      });
    }
    grid.appendChild(el);
  });
}

async function createAccount(slot, companyName) {
  const [ok, result] = await nui('createAccount', { slot, companyName: companyName || null });
  if (!ok) { toast(typeof result === 'string' ? result : 'Erreur de création', 'error'); return; }
  if (result && result.accounts) {
    state.data = result;
    toast('Compte créé avec succès', 'success');
    state.view = 'accounts';
    render();
  }
}

/* ══════════ COMPANY ══════════ */
function renderCompany() {
  $('#screenTitle').textContent = 'Compte Entreprise';
  $('#screenSub').textContent = 'Créez votre micro-entreprise';
  const v = $('#tabletView');
  v.innerHTML = `
    <form id="companyForm" class="company-form">
      <div class="form-group"><label>Nom de l'entreprise</label><input id="coName" placeholder="Mon entreprise" minlength="3" maxlength="48" required/></div>
      <button class="btn btn-primary" type="submit">Créer le compte entreprise</button>
    </form>
  `;
  $('#companyForm').addEventListener('submit', (e) => {
    e.preventDefault();
    createAccount(state._catalogSlot || 4, $('#coName').value.trim());
  });
}

/* ══════════ ATM ══════════ */
function renderAtm() {
  const step = state.atmStep;
  const av = $('#atmView');

  if (step === 'cards') {
    const cards = (state.atmCards || []).filter(c => !c.stolen && !c.disabled);
    av.innerHTML = '<p style="text-align:center;margin-bottom:16px;font-size:14px;font-weight:600">Insérez votre carte</p><div class="atm-cards" id="atmCardsList"></div>';
    const list = $('#atmCardsList');
    if (cards.length === 0) {
      list.innerHTML = '<p style="text-align:center;color:var(--muted);font-size:13px">Aucune carte dans votre inventaire</p>';
    } else {
      cards.forEach(c => {
        const btn = document.createElement('button');
        btn.className = 'atm-card-btn';
        btn.innerHTML = `<span class="acb-name">${c.firstname} ${c.lastname}</span><span class="acb-num">${c.masked}</span>`;
        btn.addEventListener('click', () => {
          state.atmSession = { cardId: c.cardId, accountId: c.accountId };
          state.atmStep = 'pin';
          renderAtm();
        });
        list.appendChild(btn);
      });
    }
  }

  else if (step === 'pin') {
    let pin = '';
    av.innerHTML = `
      <p style="text-align:center;margin-bottom:12px;font-size:14px;font-weight:600">Code PIN</p>
      <div class="atm-pin-display" id="pinDisplay"></div>
      <div class="pin-grid" id="pinGrid"></div>
    `;
    const display = $('#pinDisplay');
    const grid = $('#pinGrid');

    for (let i = 1; i <= 9; i++) addKey(i.toString());
    addKey('C', 'clear');
    addKey('0');
    addKey('OK', 'ok');

    function addKey(label, cls) {
      const btn = document.createElement('button');
      btn.className = 'pin-key' + (cls ? ' ' + cls : '');
      btn.textContent = label;
      btn.addEventListener('click', async () => {
        if (label === 'C') { pin = ''; display.textContent = ''; return; }
        if (label === 'OK') {
          if (pin.length !== 4) return;
          const [ok, result] = await nui('atmPin', { cardId: state.atmSession.cardId, pin });
          if (!ok) { toast(typeof result === 'string' ? result : 'Code incorrect', 'error'); pin = ''; display.textContent = ''; return; }
          state.atmSession = { ...state.atmSession, ...result };
          state.atmStep = 'dashboard';
          renderAtm();
          return;
        }
        if (pin.length < 4) {
          pin += label;
          display.textContent = '•'.repeat(pin.length);
        }
      });
      grid.appendChild(btn);
    }
  }

  else if (step === 'dashboard') {
    const s = state.atmSession;
    av.innerHTML = `
      <div class="atm-dash">
        <div class="ad-holder">${s.holder || ''}</div>
        <div class="ad-balance">${money(s.balance)}</div>
        <div class="ad-cash">Liquide : ${money(s.cash)}</div>
        <div class="atm-dash-actions">
          <button class="btn btn-primary" id="atmDeposit">Déposer</button>
          <button class="btn btn-primary" id="atmWithdraw">Retirer</button>
        </div>
      </div>
    `;

    $('#atmDeposit').addEventListener('click', () => {
      const max = Math.min(s.cash, s.ceiling - s.balance);
      openModal('Déposer au DAB', `Liquide : ${money(s.cash)}`, max, async (amount) => {
        const [ok, result] = await nui('atmDeposit', { cardId: s.cardId, amount });
        if (!ok) { toast(typeof result === 'string' ? result : 'Erreur', 'error'); return; }
        if (result) {
          state.atmSession.balance = result.balance;
          state.atmSession.cash = result.cash;
          if (state.data) state.data.cash = result.cash;
          toast(`${money(amount)} déposé`, 'success');
          renderAtm();
        }
      });
    });

    $('#atmWithdraw').addEventListener('click', () => {
      openModal('Retirer au DAB', `Solde : ${money(s.balance)}`, s.balance, async (amount) => {
        const [ok, result] = await nui('atmWithdraw', { cardId: s.cardId, amount });
        if (!ok) { toast(typeof result === 'string' ? result : 'Erreur', 'error'); return; }
        if (result) {
          state.atmSession.balance = result.balance;
          state.atmSession.cash = result.cash;
          if (state.data) state.data.cash = result.cash;
          toast(`${money(amount)} retiré`, 'success');
          renderAtm();
        }
      });
    });
  }
}

/* ══════════ SHOP PAYMENT MODAL ══════════ */
const shopPay = $('#shopPay');

function openShopPayment(cards, amount) {
  state.spCards = cards;
  state.spAmount = amount;
  state.spSelectedCard = null;
  state.spStep = 'method';
  shopPay.classList.remove('hidden');
  if (amount > 0) {
    $('#spAmount').textContent = money(amount);
    document.querySelector('.sp-amount-bar').style.display = '';
  } else {
    document.querySelector('.sp-amount-bar').style.display = 'none';
  }
  renderShopPay();
}

function renderShopPay() {
  const body = $('#spBody');
  const step = state.spStep;

  if (step === 'method') {
    body.innerHTML = `
      <p class="sp-step-title">Comment souhaitez-vous payer ?</p>
      <div class="sp-method-grid">
        <div class="sp-method-btn" id="spCash">
          <div class="sp-m-icon">💵</div>
          <div class="sp-m-label">Espèces</div>
          <div class="sp-m-sub">Payer en liquide</div>
        </div>
        <div class="sp-method-btn" id="spCard">
          <div class="sp-m-icon">💳</div>
          <div class="sp-m-label">Carte bancaire</div>
          <div class="sp-m-sub">Payer avec Acardia Bank</div>
        </div>
      </div>
    `;
    $('#spCash').addEventListener('click', () => {
      shopPay.classList.add('hidden');
      nui('shopPayResult', { method: 'cash' });
    });
    $('#spCard').addEventListener('click', () => {
      const cards = (state.spCards || []).filter(c => !c.stolen && !c.disabled);
      if (cards.length === 0) {
        toast('Aucune carte bancaire active', 'error');
        return;
      }
      state.spStep = 'selectCard';
      renderShopPay();
    });
  }

  else if (step === 'selectCard') {
    const cards = (state.spCards || []).filter(c => !c.stolen && !c.disabled);
    body.innerHTML = `<p class="sp-step-title">Sélectionnez votre carte</p><div class="sp-cards-list" id="spCardsList"></div>`;
    const list = $('#spCardsList');
    cards.forEach(c => {
      const wrap = document.createElement('div');
      wrap.className = 'sp-card-option';
      wrap.innerHTML = `
        <div class="card-plastic">
          <div>
            <div class="cp-brand">Acardia Bank</div>
            <div class="cp-chip"></div>
          </div>
          <div class="cp-number">${c.masked}</div>
          <div class="cp-bottom">
            <div class="cp-holder">${c.firstname} ${c.lastname}</div>
            <div class="cp-status active">Active</div>
          </div>
        </div>
      `;
      wrap.addEventListener('click', () => {
        state.spSelectedCard = c;
        state.spStep = 'pin';
        renderShopPay();
      });
      list.appendChild(wrap);
    });
  }

  else if (step === 'pin') {
    let pin = '';
    const card = state.spSelectedCard;
    body.innerHTML = `
      <div class="sp-card-option selected" style="pointer-events:none;margin-bottom:16px">
        <div class="card-plastic" style="height:140px">
          <div><div class="cp-brand">Acardia Bank</div><div class="cp-chip"></div></div>
          <div class="cp-number">${card.masked}</div>
          <div class="cp-bottom">
            <div class="cp-holder">${card.firstname} ${card.lastname}</div>
          </div>
        </div>
      </div>
      <div class="sp-pin-wrap">
        <p class="sp-step-title">Entrez votre code PIN</p>
        <div class="sp-pin-dots" id="spPinDots">
          <div class="sp-pin-dot"></div><div class="sp-pin-dot"></div>
          <div class="sp-pin-dot"></div><div class="sp-pin-dot"></div>
        </div>
        <div class="sp-pin-grid" id="spPinGrid"></div>
      </div>
    `;
    const dots = body.querySelectorAll('.sp-pin-dot');
    const grid = $('#spPinGrid');

    function updateDots() {
      dots.forEach((d, i) => d.classList.toggle('filled', i < pin.length));
    }

    function addKey(label, cls) {
      const btn = document.createElement('button');
      btn.className = 'sp-pin-key' + (cls ? ' ' + cls : '');
      btn.textContent = label;
      btn.addEventListener('click', async () => {
        if (label === 'C') { pin = ''; updateDots(); return; }
        if (label === 'OK') {
          if (pin.length !== 4) return;
          shopPay.classList.add('hidden');
          nui('shopPayResult', { method: 'card', cardId: card.cardId, pin });
          return;
        }
        if (pin.length < 4) { pin += label; updateDots(); }
      });
      grid.appendChild(btn);
    }

    for (let i = 1; i <= 9; i++) addKey(i.toString());
    addKey('C', 'action');
    addKey('0');
    addKey('OK', 'action');
  }
}

$('#spClose').addEventListener('click', () => {
  shopPay.classList.add('hidden');
  nui('shopPayResult', { method: 'cancel' });
});

/* ══════════ NUI LISTENERS ══════════ */
window.addEventListener('message', (e) => {
  const msg = e.data;
  if (msg.action === 'openTablet') {
    state.data = msg.data;
    state.view = 'home';
    state.accountDetail = null;
    state.selectedCard = null;
    root.classList.remove('hidden');
    tablet.classList.remove('hidden');
    atm.classList.add('hidden');
    render();
  }
  else if (msg.action === 'openAtm') {
    state.atmStep = 'cards';
    state.atmSession = null;
    state.atmCards = msg.cards || [];
    root.classList.remove('hidden');
    atm.classList.remove('hidden');
    tablet.classList.add('hidden');
    renderAtm();
  }
  else if (msg.action === 'openShopPayment') {
    openShopPayment(msg.cards || [], msg.amount || 0);
  }
  else if (msg.action === 'close') {
    closeAll();
  }
});

function closeAll() {
  root.classList.add('hidden');
  tablet.classList.add('hidden');
  atm.classList.add('hidden');
  modal.classList.add('hidden');
  shopPay.classList.add('hidden');
}

$('#btnClose').addEventListener('click', () => { nui('close'); closeAll(); });
$('#atmClose').addEventListener('click', () => { nui('close'); closeAll(); });

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') { nui('close'); closeAll(); }
});

})();
