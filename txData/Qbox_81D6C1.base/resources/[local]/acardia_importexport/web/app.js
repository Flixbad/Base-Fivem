const app = document.getElementById('app');
const balanceEl = document.getElementById('balance');
const balanceCard = document.getElementById('balance-card');
const employeesEl = document.getElementById('employees');
const transactionsEl = document.getElementById('transactions');
const myTxEl = document.getElementById('my-transactions');
const dutyStatus = document.getElementById('duty-status');
const dutyBtn = document.getElementById('btn-duty');
const tabletTitle = document.getElementById('tablet-title');
const playerMeta = document.getElementById('player-meta');

let state = {
  isBoss: false,
  onDuty: false,
  myTransactions: [],
  employees: [],
  transactions: [],
  grades: [],
};

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
  el.innerHTML = list
    .map((t) => {
      const cls = Number(t.amount) >= 0 ? 'amount-pos' : 'amount-neg';
      return `
        <div class="card">
          <h3 class="${cls}">${money(t.amount)} <span style="color:var(--muted);font-weight:500">· ${t.type}</span></h3>
          <p>${t.details || ''} · ${t.created_at || ''}</p>
        </div>`;
    })
    .join('');
}

function renderEmployees() {
  if (!state.employees || !state.employees.length) {
    employeesEl.innerHTML = '<div class="card"><p>Aucun employe en ligne.</p></div>';
    return;
  }

  employeesEl.innerHTML = state.employees
    .map((e) => {
      const options = (state.grades || [])
        .map(
          (g) =>
            `<option value="${g.level}" ${Number(e.grade) === Number(g.level) ? 'selected' : ''}>${g.label}</option>`
        )
        .join('');
      return `
        <div class="card">
          <h3>${e.name}</h3>
          <p>${e.gradeLabel || 'Grade ' + e.grade} · ${e.onDuty ? 'En service' : 'Hors service'}</p>
          <div class="row">
            <select data-cid="${e.citizenid}" class="grade-select">${options}</select>
            <button class="ok" data-setgrade="${e.citizenid}">Appliquer</button>
            <button class="danger" data-fire="${e.citizenid}">Virer</button>
          </div>
        </div>`;
    })
    .join('');
}

function applyPayload(payload) {
  if (!payload) return;
  state = payload;

  tabletTitle.textContent = payload.isBoss ? 'Tablette Patron' : 'Tablette Employe';
  playerMeta.textContent = `${payload.playerName || ''} · ${payload.gradeLabel || ''}`;

  dutyStatus.textContent = payload.onDuty ? 'En service' : 'Hors service';
  dutyBtn.textContent = payload.onDuty ? 'Quitter le service' : 'Prendre service';
  dutyBtn.classList.toggle('danger', !!payload.onDuty);
  dutyBtn.classList.toggle('primary', !payload.onDuty);

  document.querySelectorAll('.boss-only').forEach((el) => {
    el.classList.toggle('hidden', !payload.isBoss);
  });
  balanceCard.classList.toggle('hidden', !payload.isBoss);

  if (payload.isBoss) {
    balanceEl.textContent = money(payload.balance);
    renderEmployees();
    renderTxList(transactionsEl, payload.transactions, 'Aucune transaction societe.');
  }

  renderTxList(myTxEl, payload.myTransactions, 'Aucune transaction a ton nom pour le moment.');
}

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'open') {
    app.classList.remove('hidden');
    // reset to mytx tab
    document.querySelectorAll('.tab').forEach((b) => b.classList.remove('active'));
    document.querySelector('.tab[data-tab="mytx"]').classList.add('active');
    document.getElementById('panel-mytx').classList.remove('hidden');
    document.getElementById('panel-employees').classList.add('hidden');
    document.getElementById('panel-transactions').classList.add('hidden');
    applyPayload(data.payload);
  }
  if (data.action === 'close') {
    app.classList.add('hidden');
  }
  if (data.action === 'craftProgress') {
    handleCraftProgress(data);
  }
});

document.querySelectorAll('.tab').forEach((btn) => {
  btn.addEventListener('click', () => {
    if (btn.classList.contains('hidden')) return;
    document.querySelectorAll('.tab').forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');
    const tab = btn.dataset.tab;
    document.getElementById('panel-mytx').classList.toggle('hidden', tab !== 'mytx');
    document.getElementById('panel-employees').classList.toggle('hidden', tab !== 'employees');
    document.getElementById('panel-transactions').classList.toggle('hidden', tab !== 'transactions');
  });
});

document.getElementById('btn-close').addEventListener('click', () => post('close'));
document.getElementById('btn-refresh').addEventListener('click', async () => {
  const res = await post('refresh');
  if (res && res.payload) applyPayload(res.payload);
});
document.getElementById('btn-duty').addEventListener('click', async () => {
  const res = await post('toggleDuty');
  if (res && res.payload) applyPayload(res.payload);
});
document.getElementById('btn-hire').addEventListener('click', async () => {
  const res = await post('hireClosest');
  if (res && res.payload) applyPayload(res.payload);
});

employeesEl.addEventListener('click', async (ev) => {
  const fireBtn = ev.target.closest('[data-fire]');
  const setBtn = ev.target.closest('[data-setgrade]');
  if (fireBtn) {
    const res = await post('fire', { citizenid: fireBtn.dataset.fire });
    if (res && res.payload) applyPayload(res.payload);
  }
  if (setBtn) {
    const cid = setBtn.dataset.setgrade;
    const select = employeesEl.querySelector(`select[data-cid="${cid}"]`);
    const res = await post('setGrade', { citizenid: cid, grade: Number(select.value) });
    if (res && res.payload) applyPayload(res.payload);
  }
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') post('close');
});

const CIRC = 2 * Math.PI * 52;
const craftBox = document.getElementById('craftProgress');
const craftRing = document.getElementById('craftRing');
const craftSeconds = document.getElementById('craftSeconds');
const craftLabel = document.getElementById('craftLabel');
let craftAnim = 0;

function handleCraftProgress(data) {
  cancelAnimationFrame(craftAnim);
  if (!data.show) {
    craftBox.classList.add('hidden');
    return;
  }

  const duration = Number(data.duration) || 60000;
  const started = performance.now();
  craftLabel.textContent = data.label || 'Fabrication';
  craftRing.style.strokeDasharray = String(CIRC);
  craftBox.classList.remove('hidden');

  const tick = (now) => {
    const elapsed = Math.min(duration, now - started);
    const left = Math.max(0, duration - elapsed);
    const frac = elapsed / duration;
    craftSeconds.textContent = String(Math.ceil(left / 1000));
    craftRing.style.strokeDashoffset = String(CIRC * frac);
    if (elapsed < duration && !craftBox.classList.contains('hidden')) {
      craftAnim = requestAnimationFrame(tick);
    }
  };
  craftAnim = requestAnimationFrame(tick);
}
