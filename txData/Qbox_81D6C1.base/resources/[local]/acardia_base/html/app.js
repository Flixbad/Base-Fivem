const hud = document.getElementById('hud');
const mapBorder = document.getElementById('mapBorder');
const clock = document.getElementById('clock');
const street = document.getElementById('street');
const zone = document.getElementById('zone');
const deathScreen = document.getElementById('deathScreen');
const deathTimerEl = document.getElementById('deathTimer');
const respawnBtn = document.getElementById('respawnBtn');

const stats = {
  hunger: document.querySelector('.stat.hunger'),
  thirst: document.querySelector('.stat.thirst'),
  energy: document.querySelector('.stat.energy'),
  armor: document.querySelector('.stat.armor'),
  health: document.querySelector('.stat.health'),
};

const R = 18;
const CIRC = 2 * Math.PI * R;
const DEATH_TIMER = 300;
let timerInterval = null;
let timerValue = DEATH_TIMER;

function setStat(name, value) {
  const el = stats[name];
  if (!el) return;
  const pct = Math.max(0, Math.min(100, Number(value) || 0));
  el.querySelector('.progress').style.strokeDasharray = `${CIRC * (pct / 100)} ${CIRC}`;
  const isLow = (name === 'armor') ? (pct > 0 && pct <= 20) : pct <= 20;
  el.classList.toggle('low', isLow);
  if (name === 'armor') el.classList.toggle('empty', pct <= 0);
}

function startTimer() {
  stopTimer();
  timerValue = DEATH_TIMER;
  if (deathTimerEl) deathTimerEl.textContent = timerValue;
  if (respawnBtn) respawnBtn.classList.add('hidden');

  timerInterval = setInterval(() => {
    timerValue--;
    if (deathTimerEl) deathTimerEl.textContent = Math.max(0, timerValue);
    if (timerValue <= 0) {
      stopTimer();
      if (respawnBtn) respawnBtn.classList.remove('hidden');
      if (deathTimerEl) deathTimerEl.textContent = '0';
    }
  }, 1000);
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
}

function showDeath() {
  if (!deathScreen) return;
  deathScreen.classList.remove('hidden');
  hud.classList.add('hidden');
  startTimer();
}

function hideDeath() {
  if (!deathScreen) return;
  deathScreen.classList.add('hidden');
  stopTimer();
  if (respawnBtn) respawnBtn.classList.add('hidden');
}

document.querySelectorAll('.death-btn[data-service]').forEach((btn) => {
  btn.addEventListener('click', () => {
    const service = btn.dataset.service;
    fetch(`https://${GetParentResourceName()}/deathCall`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ service }),
    });
  });
});

if (respawnBtn) {
  respawnBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/deathRespawn`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
  });
}

window.addEventListener('message', (event) => {
  const data = event.data || {};

  if (data.action === 'death') {
    if (data.show === false) hideDeath();
    else showDeath();
    return;
  }

  if (data.action !== 'hud') return;

  if (data.show === false) {
    hud.classList.add('hidden');
    return;
  }

  if (deathScreen && !deathScreen.classList.contains('hidden')) return;

  hud.classList.remove('hidden');
  mapBorder.classList.remove('hidden');
  if (data.time) clock.textContent = data.time;
  if (data.street) street.textContent = data.street;
  if (data.zone) zone.textContent = data.zone;
  if (data.hunger != null) setStat('hunger', data.hunger);
  if (data.thirst != null) setStat('thirst', data.thirst);
  if (data.energy != null) setStat('energy', data.energy);
  if (data.armor != null) setStat('armor', data.armor);
  if (data.health != null) setStat('health', data.health);
});

setStat('hunger', 100);
setStat('thirst', 100);
setStat('energy', 100);
setStat('armor', 0);
setStat('health', 100);
