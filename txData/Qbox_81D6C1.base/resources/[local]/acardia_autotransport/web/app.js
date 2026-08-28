const app = document.getElementById('app');

const balanceEl = document.getElementById('balance');

const balanceCard = document.getElementById('balance-card');

const employeesEl = document.getElementById('employees');

const transactionsEl = document.getElementById('transactions');

const myTxEl = document.getElementById('my-transactions');

const missionsEl = document.getElementById('missions');

const activeMissionEl = document.getElementById('active-mission');

const leaderboardEl = document.getElementById('leaderboard');

const dutyStatus = document.getElementById('duty-status');

const dutyBtn = document.getElementById('btn-duty');

const btnReport = document.getElementById('btn-report');

const btnCancel = document.getElementById('btn-cancel');



let state = {};



function money(n) {

  return '$' + Number(n || 0).toLocaleString('fr-FR');

}



function post(name, data = {}) {

  return fetch(`https://${GetParentResourceName()}/${name}`, {

    method: 'POST',

    headers: { 'Content-Type': 'application/json; charset=UTF-8' },

    body: JSON.stringify(data),

  }).then((r) => r.json());

}



function renderTxList(el, list, emptyText) {

  if (!list || !list.length) {

    el.innerHTML = `<div class="card"><p>${emptyText}</p></div>`;

    return;

  }

  el.innerHTML = list.map((t) => {

    const cls = Number(t.amount) >= 0 ? 'amount-pos' : 'amount-neg';

    return `<div class="card"><h3 class="${cls}">${money(t.amount)} · ${t.type}</h3><p>${t.details || ''}</p></div>`;

  }).join('');

}



function renderStats() {

  const s = state.stats || {};

  document.getElementById('stat-rank').textContent = s.rankLabel || 'Stagiaire';

  document.getElementById('stat-missions').textContent = s.missionsCompleted || 0;

  document.getElementById('stat-vip').textContent = s.vipDeliveries || 0;

  document.getElementById('stat-bonus').textContent = '+' + Math.round((s.rankBonus || 0) * 100) + '%';

  const next = document.getElementById('stat-next');

  if (s.nextRankLabel && s.nextRankAt != null) {

    const left = Math.max(0, s.nextRankAt - (s.missionsCompleted || 0));

    next.textContent = left > 0

      ? `${left} mission(s) avant grade ${s.nextRankLabel}`

      : 'Grade maximum atteint pour cette palier';

  } else {

    next.textContent = 'Grade maximum atteint';

  }

}



function renderLeaderboard() {

  const list = state.leaderboard || [];

  if (!list.length) {

    leaderboardEl.innerHTML = '<div class="card"><p>Aucune livraison enregistree.</p></div>';

    return;

  }

  leaderboardEl.innerHTML = list.map((row, i) =>

    `<div class="card"><h3>#${i + 1} ${row.player_name || 'Chauffeur'}</h3>

     <p>${row.missions} missions · ${money(row.earned)} genere(s)</p></div>`

  ).join('');

}



function renderEmployees() {

  if (!state.employees || !state.employees.length) {

    employeesEl.innerHTML = '<div class="card"><p>Aucun employe en ligne.</p></div>';

    return;

  }

  employeesEl.innerHTML = state.employees.map((e) => {

    const options = (state.grades || []).map((g) =>

      `<option value="${g.level}" ${Number(e.grade) === Number(g.level) ? 'selected' : ''}>${g.label}</option>`

    ).join('');

    return `<div class="card"><h3>${e.name}</h3><p>${e.gradeLabel} · ${e.onDuty ? 'En service' : 'Hors service'}</p>

      <div class="row"><select data-cid="${e.citizenid}" class="grade-select">${options}</select>

      <button class="ok" data-setgrade="${e.citizenid}">Appliquer</button>

      <button class="danger" data-fire="${e.citizenid}">Virer</button></div></div>`;

  }).join('');

}



function modeTag(mode, special, type) {

  if (type === 'order') return '<span class="tag-order">Commande client</span>';

  if (special) return '<span class="tag-vip">VIP</span>';

  if (mode === 'drive') return '<span class="tag-drive">Conduite directe</span>';

  return '<span class="tag-flatbed">Flatbed</span>';

}



function renderMissions() {

  if (state.activeMission) {

    const m = state.activeMission;

    activeMissionEl.classList.remove('hidden');

    activeMissionEl.classList.add('active-card');

    const vipClass = m.special ? ' vip' : '';

    activeMissionEl.innerHTML = `<h3>Mission en cours</h3>

      <p><strong>${m.label}</strong></p>

      <p>${m.mode} · ${m.model} · Prime ${money(m.payout)}</p>

      <span class="stage-pill${vipClass}">${m.stageLabel || m.stage || 'En cours'}</span>`;

    btnReport.classList.remove('hidden');

    btnCancel.classList.remove('hidden');

  } else {

    activeMissionEl.classList.add('hidden');

    activeMissionEl.classList.remove('active-card');

    btnReport.classList.add('hidden');

    btnCancel.classList.add('hidden');

  }



  const list = state.missions || [];

  if (!list.length) {

    missionsEl.innerHTML = '<div class="card"><p>Aucune mission disponible.</p></div>';

    return;

  }



  missionsEl.innerHTML = list.map((m) => {

    const tags = modeTag(m.mode, m.special, m.type);

    const route = m.pickupLabel && m.deliveryLabel

      ? `${m.pickupLabel} → ${m.deliveryLabel}`

      : `${m.mode} · ${m.model}`;

    const payload = m.type === 'order' ? JSON.stringify({ type: 'order', id: m.id }) : m.id;

    return `<div class="card"><h3>${m.label} ${tags}</h3>

      <p>${route} · ${m.model} · Prime ${money(m.payout)}</p>

      <button class="primary accept-mission" data-payload='${payload}'>Accepter</button></div>`;

  }).join('');

}



function applyPayload(payload) {

  if (!payload) return;

  state = payload;

  document.getElementById('tablet-title').textContent = payload.isBoss ? 'Tablette Patron' : 'Tablette Chauffeur';

  document.getElementById('player-meta').textContent = `${payload.playerName || ''} · ${payload.gradeLabel || ''}`;

  dutyStatus.textContent = payload.onDuty ? 'En service' : 'Hors service';

  dutyBtn.textContent = payload.onDuty ? 'Quitter le service' : 'Prendre service';

  document.querySelectorAll('.boss-only').forEach((el) => el.classList.toggle('hidden', !payload.isBoss));

  balanceCard.classList.toggle('hidden', !payload.isBoss);

  renderStats();

  if (payload.isBoss) {

    balanceEl.textContent = money(payload.balance);

    renderEmployees();

    renderLeaderboard();

    renderTxList(transactionsEl, payload.transactions, 'Aucune transaction.');

  }

  renderTxList(myTxEl, payload.myTransactions, 'Aucune livraison enregistree.');

  renderMissions();

}



window.addEventListener('message', (event) => {

  const data = event.data || {};

  if (data.action === 'open') {

    app.classList.remove('hidden');

    applyPayload(data.payload);

  }

  if (data.action === 'close') app.classList.add('hidden');

});



document.querySelectorAll('.tab').forEach((btn) => {

  btn.addEventListener('click', () => {

    if (btn.classList.contains('hidden')) return;

    document.querySelectorAll('.tab').forEach((b) => b.classList.remove('active'));

    btn.classList.add('active');

    ['missions', 'mytx', 'leaderboard', 'employees', 'transactions'].forEach((tab) => {

      const el = document.getElementById(`panel-${tab}`);

      if (el) el.classList.toggle('hidden', btn.dataset.tab !== tab);

    });

  });

});



document.getElementById('btn-close').addEventListener('click', () => post('close'));

document.getElementById('btn-refresh').addEventListener('click', async () => {

  const res = await post('refresh');

  if (res.payload) applyPayload(res.payload);

});

document.getElementById('btn-duty').addEventListener('click', async () => {

  const res = await post('toggleDuty');

  if (res.payload) applyPayload(res.payload);

});

document.getElementById('btn-hire').addEventListener('click', async () => {

  const res = await post('hireClosest');

  if (res.payload) applyPayload(res.payload);

});

document.getElementById('btn-report').addEventListener('click', () => post('reportTheft'));

document.getElementById('btn-cancel').addEventListener('click', async () => {

  const res = await post('cancelMission');

  if (res.payload) applyPayload(res.payload);

});



missionsEl.addEventListener('click', async (ev) => {

  const btn = ev.target.closest('.accept-mission');

  if (!btn) return;

  let payload = btn.dataset.payload;

  try { payload = JSON.parse(payload); } catch (_) { payload = Number(payload); }

  await post('acceptMission', { payload });

});



employeesEl.addEventListener('click', async (ev) => {

  const fire = ev.target.closest('[data-fire]');

  const setgrade = ev.target.closest('[data-setgrade]');

  if (fire) {

    const res = await post('fire', { citizenid: fire.dataset.fire });

    if (res.payload) applyPayload(res.payload);

  }

  if (setgrade) {

    const cid = setgrade.dataset.setgrade;

    const select = employeesEl.querySelector(`select[data-cid="${cid}"]`);

    const res = await post('setGrade', { citizenid: cid, grade: select.value });

    if (res.payload) applyPayload(res.payload);

  }

});



document.addEventListener('keydown', (e) => {

  if (e.key === 'Escape') post('close');

});


