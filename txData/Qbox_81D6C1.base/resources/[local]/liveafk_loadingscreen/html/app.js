(() => {
  const tips = [
    'Respecte le RP : reste dans ton personnage, meme en AFK mental.',
    'Le job Acardia Export se lance depuis le QG aux docks.',
    'Utilise F6 pour la tablette entreprise quand tu as le job.',
    'Monte en service avant d ouvrir le garage societe.',
    'Les fonds de societe paient les ingredients et les camions.',
    'Un bon RP, c est aussi savoir ecouter avant de parler.',
    'Acardia RP V2 — on est chaud, mais on reste fair-play.',
    'Pense a ranger le camion entreprise apres ta run.',
  ];

  const phases = [
    { min: 0, label: 'INITIALISATION', status: 'Handshake FiveM…' },
    { min: 0.12, label: 'ASSETS', status: 'Chargement des assets…' },
    { min: 0.35, label: 'CARTE', status: 'Streaming de la map…' },
    { min: 0.55, label: 'SCRIPTS', status: 'Demarrage des resources…' },
    { min: 0.78, label: 'SESSION', status: 'Ouverture de session…' },
    { min: 0.94, label: 'PRESQUE PRET', status: 'Derniere synchro…' },
  ];

  const el = {
    stage: document.getElementById('stage'),
    bar: document.getElementById('bar'),
    barGlow: document.getElementById('barGlow'),
    crownTip: document.getElementById('crownTip'),
    percent: document.getElementById('percent'),
    phase: document.getElementById('phase'),
    statusText: document.getElementById('statusText'),
    tip: document.getElementById('tip'),
    muteBtn: document.getElementById('muteBtn'),
    vol: document.getElementById('vol'),
    eq: document.getElementById('eq'),
    bgm: document.getElementById('bgm'),
    fx: document.getElementById('fx'),
  };

  let progress = 0;
  let tipIndex = 0;
  let muted = false;

  /* ---- Music ---- */
  function applyVolume() {
    const v = Number(el.vol.value) / 100;
    el.bgm.volume = muted ? 0 : v;
  }

  async function startMusic() {
    applyVolume();
    try {
      await el.bgm.play();
      el.eq.classList.remove('is-paused');
    } catch (_) {
      // Autoplay bloque parfois : un clic debloque
      const unlock = () => {
        el.bgm.play().catch(() => {});
        el.eq.classList.remove('is-paused');
        window.removeEventListener('click', unlock);
        window.removeEventListener('keydown', unlock);
      };
      window.addEventListener('click', unlock);
      window.addEventListener('keydown', unlock);
    }
  }

  el.muteBtn.addEventListener('click', () => {
    muted = !muted;
    el.muteBtn.classList.toggle('is-muted', muted);
    el.muteBtn.textContent = muted ? '✕' : '♪';
    el.eq.classList.toggle('is-paused', muted || el.bgm.paused);
    applyVolume();
    if (!muted) startMusic();
  });

  el.vol.addEventListener('input', applyVolume);

  /* ---- Progress UI ---- */
  function setProgress(frac) {
    progress = Math.max(progress, Math.min(1, frac || 0));
    const pct = Math.floor(progress * 100);
    const width = `${progress * 100}%`;

    el.bar.style.width = width;
    el.barGlow.style.left = width;
    el.crownTip.style.left = width;
    el.percent.textContent = `${pct}%`;

    let current = phases[0];
    for (const p of phases) {
      if (progress >= p.min) current = p;
    }
    el.phase.textContent = current.label;
    el.statusText.textContent = current.status;
  }

  function rotateTip() {
    el.tip.classList.add('is-swap');
    setTimeout(() => {
      tipIndex = (tipIndex + 1) % tips.length;
      el.tip.textContent = tips[tipIndex];
      el.tip.classList.remove('is-swap');
    }, 320);
  }

  /* ---- Particles (crowns + shards) ---- */
  const ctx = el.fx.getContext('2d');
  let w = 0;
  let h = 0;
  const particles = [];

  function resize() {
    w = el.fx.width = window.innerWidth;
    h = el.fx.height = window.innerHeight;
  }

  function spawnParticle() {
    const kind = Math.random() < 0.35 ? 'crown' : 'shard';
    particles.push({
      kind,
      x: Math.random() * w,
      y: h + 20 + Math.random() * 80,
      size: kind === 'crown' ? 10 + Math.random() * 14 : 3 + Math.random() * 8,
      speed: 0.35 + Math.random() * 1.1,
      drift: (Math.random() - 0.5) * 0.6,
      rot: Math.random() * Math.PI * 2,
      rotSpeed: (Math.random() - 0.5) * 0.03,
      alpha: 0.15 + Math.random() * 0.45,
    });
  }

  function drawCrown(p) {
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(p.rot);
    ctx.globalAlpha = p.alpha;
    ctx.fillStyle = '#8a2be2';
    ctx.font = `${p.size}px serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.shadowColor = 'rgba(138,43,226,0.8)';
    ctx.shadowBlur = 12;
    ctx.fillText('♛', 0, 0);
    ctx.restore();
  }

  function drawShard(p) {
    ctx.save();
    ctx.translate(p.x, p.y);
    ctx.rotate(p.rot);
    ctx.globalAlpha = p.alpha;
    ctx.fillStyle = '#a855f7';
    ctx.beginPath();
    ctx.moveTo(0, -p.size);
    ctx.lineTo(p.size * 0.45, 0);
    ctx.lineTo(0, p.size * 0.55);
    ctx.lineTo(-p.size * 0.45, 0);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  }

  function tickFx() {
    ctx.clearRect(0, 0, w, h);

    if (particles.length < 28 && Math.random() < 0.2) spawnParticle();

    for (let i = particles.length - 1; i >= 0; i -= 1) {
      const p = particles[i];
      p.y -= p.speed;
      p.x += p.drift;
      p.rot += p.rotSpeed;
      p.alpha *= 0.9985;

      if (p.kind === 'crown') drawCrown(p);
      else drawShard(p);

      if (p.y < -40 || p.alpha < 0.04) particles.splice(i, 1);
    }

    requestAnimationFrame(tickFx);
  }

  /* ---- FiveM handlers ---- */
  window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.eventName === 'loadProgress') {
      setProgress(data.loadFraction || 0);
      return;
    }

    if (data.action === 'fadeOut') {
      el.stage.classList.add('is-leaving');
      const fade = setInterval(() => {
        if (el.bgm.volume > 0.02) el.bgm.volume = Math.max(0, el.bgm.volume - 0.04);
        else {
          el.bgm.pause();
          clearInterval(fade);
        }
      }, 40);
    }
  });

  /* ---- Boot ---- */
  window.addEventListener('resize', resize);
  resize();
  for (let i = 0; i < 12; i += 1) spawnParticle();
  tickFx();

  el.tip.textContent = tips[0];
  setInterval(rotateTip, 5500);
  setProgress(0.02);
  startMusic();

  // Soft fake crawl si aucun event (preview navigateur)
  if (!window.invokeNative) {
    let fake = 0;
    const id = setInterval(() => {
      fake = Math.min(0.97, fake + 0.008);
      setProgress(fake);
      if (fake >= 0.97) clearInterval(id);
    }, 120);
  }
})();
