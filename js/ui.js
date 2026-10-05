'use strict';
// Interface em HTML: menu de heróis, HUD, subir de nível, loja, pausa e fim de jogo

const UI = {
  game: null,
  el: {},
  selectedHero: null,
  heroCanvases: [],
  levelUpPick: null,
  inputLockUntil: 0,
  weaponSig: '',
  quitArmed: false,

  $(id) {
    if (!this.el[id]) this.el[id] = document.getElementById(id);
    return this.el[id];
  },

  init(game) {
    this.game = game;
    this.buildHeroGrid();
    const last = storageGet('hvc-last-hero', HEROES[0].id);
    this.selectHero(HEROES.some(h => h.id === last) ? last : HEROES[0].id);

    this.$('btn-start').addEventListener('click', () => this.startGame());
    this.$('btn-pause').addEventListener('click', () => game.togglePause());
    this.$('btn-resume').addEventListener('click', () => game.togglePause());
    this.$('btn-mute').addEventListener('click', () => {
      Sfx.setMuted(!Sfx.muted);
      this.updateMuteLabel();
    });
    this.$('btn-quit').addEventListener('click', () => {
      if (!this.quitArmed) {
        this.quitArmed = true;
        this.$('btn-quit').textContent = 'Toque de novo para desistir';
        return;
      }
      game.quitToMenu();
    });
    this.$('btn-reroll').addEventListener('click', () => game.reroll());
    this.$('btn-next').addEventListener('click', () => game.nextWave());
    this.$('btn-retry').addEventListener('click', () => {
      this.hideScreens();
      game.newRun(game.hero);
    });
    this.$('btn-menu').addEventListener('click', () => game.quitToMenu());
    this.updateMuteLabel();

    window.addEventListener('keydown', e => {
      const s = game.state;
      const digit = /^(Digit|Numpad)([1-4])$/.exec(e.code);
      if (s === 'menu' && e.code === 'Enter') this.startGame();
      else if (s === 'levelup' && digit && performance.now() > this.inputLockUntil) this.levelUpPick(+digit[2] - 1);
      else if (s === 'shop' && digit) game.buy(+digit[2] - 1);
      else if (s === 'shop' && e.code === 'KeyR') game.reroll();
    });

    this.showMenu();
  },

  // ---------- Menu ----------

  buildHeroGrid() {
    const grid = this.$('hero-grid');
    grid.innerHTML = '';
    this.heroCanvases = [];
    HEROES.forEach(h => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'hero-card';
      btn.dataset.id = h.id;
      btn.style.setProperty('--hero', h.color);
      const cv = document.createElement('canvas');
      cv.width = 160;
      cv.height = 160;
      cv.className = 'hero-portrait';
      const name = document.createElement('span');
      name.className = 'hero-name';
      name.textContent = h.name;
      btn.append(cv, name);
      btn.addEventListener('click', () => this.selectHero(h.id));
      btn.addEventListener('dblclick', () => this.startGame());
      grid.append(btn);
      this.heroCanvases.push({ hero: h, ctx: cv.getContext('2d'), btn });
    });
  },

  animateMenu(t) {
    this.heroCanvases.forEach((hc, i) => {
      const ctx = hc.ctx;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, 160, 160);
      ctx.setTransform(2, 0, 0, 2, 0, 0);
      const selected = this.selectedHero === hc.hero;
      Sprites.hero(ctx, hc.hero, 40, 48, 19, 1, t + i * 0.7, { moving: selected });
    });
  },

  selectHero(id) {
    const h = HEROES.find(x => x.id === id);
    this.selectedHero = h;
    storageSet('hvc-last-hero', id);
    for (const hc of this.heroCanvases) hc.btn.setAttribute('aria-pressed', String(hc.hero === h));
    const w = WEAPONS[h.startWeapon];
    const rec = storageGet('hvc-records', {})[h.id];
    const recText = !rec ? 'Ainda não jogou com este herói' : rec > TOTAL_WAVES ? 'Recorde: derrotou A Calamidade!' : `Recorde: chegou à onda ${rec}`;
    const mods = formatMods(h.mods).map(m => `<li class="${m.good ? 'good' : 'bad'}">${m.text}</li>`).join('');
    this.$('hero-detail').innerHTML = `
      <div class="detail-head" style="--hero:${h.color}">
        <h2 class="detail-name">${h.name}</h2>
        <span class="detail-title">${h.title}</span>
      </div>
      <p class="detail-desc">${h.desc}</p>
      <div class="detail-grid">
        <div class="detail-block">
          <span class="label">Habilidade · Espaço</span>
          <strong>${h.ability.icon} ${h.ability.name}</strong>
          <p>${h.ability.desc}</p>
          <span class="muted">Recarga: ${h.ability.cooldown}s</span>
        </div>
        <div class="detail-block">
          <span class="label">Arma inicial</span>
          <strong>${w.icon} ${w.name}</strong>
          <p>${w.desc}</p>
        </div>
        <div class="detail-block">
          <span class="label">Atributos</span>
          <ul class="mod-list">${mods}</ul>
        </div>
      </div>
      <p class="record">${recText}</p>`;
    this.$('btn-start').textContent = `Jogar com ${h.name}`;
  },

  startGame() {
    if (!this.selectedHero) return;
    this.hideScreens();
    this.game.newRun(this.selectedHero);
  },

  showMenu() {
    this.$('hud').hidden = true;
    this.hideBossBar();
    this.selectHero(this.selectedHero.id);
    this.showScreen('menu');
  },

  // ---------- Telas ----------

  showScreen(name) {
    for (const s of ['menu', 'levelup', 'shop', 'pause', 'end']) this.$('screen-' + s).hidden = s !== name;
    const panel = this.$('screen-' + name).querySelector('.panel');
    if (panel) panel.focus({ preventScroll: true });
  },

  hideScreens() {
    for (const s of ['menu', 'levelup', 'shop', 'pause', 'end']) this.$('screen-' + s).hidden = true;
  },

  showHUD() {
    this.$('hud').hidden = false;
    const ab = this.game.player.hero.ability;
    this.$('ability-icon').textContent = ab.icon;
    this.$('btn-ability').title = `${ab.name} (Espaço)`;
    this.$('btn-ability').setAttribute('aria-label', `Usar habilidade: ${ab.name}`);
    this.weaponSig = '';
  },

  // ---------- HUD ----------

  setText(el, v) {
    if (el._v !== v) {
      el._v = v;
      el.textContent = v;
    }
  },

  setWidth(el, frac) {
    const v = (clamp(frac, 0, 1) * 100).toFixed(1) + '%';
    if (el._w !== v) {
      el._w = v;
      el.style.width = v;
    }
  },

  updateHUD(game) {
    const p = game.player;
    const hp = Math.max(0, Math.ceil(p.hp));
    this.setWidth(this.$('hp-fill'), p.hp / p.stats.maxHp);
    this.setText(this.$('hp-text'), `${hp} / ${p.stats.maxHp}`);
    this.setWidth(this.$('xp-fill'), p.xp / p.xpToNext());
    this.setText(this.$('lvl-text'), `Nível ${p.level}`);
    this.setText(this.$('gold-text'), String(Math.floor(p.gold)));
    this.setText(this.$('wave-text'), `Onda ${game.wave}/${TOTAL_WAVES}`);
    let timer;
    if (game.isBossWave) timer = game.boss ? 'Chefe' : game.bossDefeated ? '✓' : '…';
    else timer = String(Math.max(0, Math.ceil(game.waveDuration - game.waveTime)));
    this.setText(this.$('timer-text'), timer);
    this.$('timer-text').classList.toggle('urgent', !game.isBossWave && game.waveDuration - game.waveTime <= 5);

    const frac = p.abilityTimer / p.abilityCooldown;
    const btn = this.$('btn-ability');
    const cdKey = frac.toFixed(3);
    if (btn._cd !== cdKey) {
      btn._cd = cdKey;
      btn.style.setProperty('--cd', cdKey);
      btn.classList.toggle('ready', frac <= 0);
    }
    this.setText(this.$('ability-cd'), frac > 0 ? String(Math.ceil(p.abilityTimer)) : '');

    if (game.boss) {
      this.setWidth(this.$('boss-fill'), game.boss.hp / game.boss.maxHp);
    }

    const sig = p.weapons.map(w => w.def.id + w.level).join('|');
    if (sig !== this.weaponSig) {
      this.weaponSig = sig;
      const slots = [];
      for (let i = 0; i < MAX_WEAPONS; i++) {
        const w = p.weapons[i];
        slots.push(w
          ? `<div class="slot" title="${w.def.name}"><span>${w.def.icon}</span><span class="slot-lv">${w.level}</span></div>`
          : '<div class="slot empty"></div>');
      }
      this.$('weapon-slots').innerHTML = slots.join('');
    }

    this.$('vignette').classList.toggle('danger', p.hp / p.stats.maxHp < 0.3 && game.state === 'playing');
  },

  showBossBar(name) {
    this.$('boss-name').textContent = name;
    this.$('boss-bar').hidden = false;
  },

  hideBossBar() {
    this.$('boss-bar').hidden = true;
  },

  banner(title, sub) {
    const b = this.$('banner');
    this.$('banner-title').textContent = title;
    this.$('banner-sub').textContent = sub || '';
    b.classList.remove('show');
    void b.offsetWidth;
    b.classList.add('show');
  },

  toast(text) {
    const t = document.createElement('div');
    t.className = 'toast';
    t.textContent = text;
    this.$('toasts').append(t);
    setTimeout(() => t.remove(), 2800);
  },

  // ---------- Cartas ----------

  makeCard(opt, hotkey, price = null, canAfford = true) {
    const card = document.createElement('button');
    card.type = 'button';
    card.className = `card r-${RARITIES[opt.rarity].id}`;
    if (price !== null && !canAfford) card.classList.add('cant-afford');
    const effects = opt.effects.map(e => `<li class="${e.neutral ? 'neutral' : e.good ? 'good' : 'bad'}">${e.text}</li>`).join('');
    const tag = opt.kind === 'weapon' ? (opt.isNew ? 'Nova arma' : 'Melhoria de arma') : opt.kind === 'item' ? 'Item' : 'Atributo';
    card.innerHTML = `
      <span class="card-top"><span class="card-rarity">${RARITIES[opt.rarity].name}</span><kbd>${hotkey}</kbd></span>
      <span class="card-icon" aria-hidden="true">${opt.icon}</span>
      <span class="card-name">${opt.name}</span>
      <span class="card-tag">${tag}</span>
      <ul class="card-effects">${effects}</ul>
      ${price !== null ? `<span class="card-price"><span class="coin"></span>${price}</span>` : ''}`;
    return card;
  },

  openLevelUp(level, options, onPick) {
    this.showScreen('levelup');
    this.$('levelup-sub').textContent = `Nível ${level}. Escolha uma melhoria.`;
    const wrap = this.$('levelup-cards');
    wrap.innerHTML = '';
    wrap.style.setProperty('--n', options.length);
    let picked = false;
    const choose = opt => {
      if (picked || performance.now() < this.inputLockUntil) return;
      picked = true;
      onPick(opt);
    };
    options.forEach((opt, i) => {
      const card = this.makeCard(opt, i + 1);
      card.addEventListener('click', () => choose(opt));
      wrap.append(card);
    });
    this.levelUpPick = i => options[i] && choose(options[i]);
    this.inputLockUntil = performance.now() + 350;
  },

  openShop(game) {
    this.showScreen('shop');
    const p = game.player;
    const gold = Math.floor(p.gold);
    const next = game.wave + 1;
    this.$('shop-title').textContent = `Onda ${game.wave} concluída`;
    this.$('shop-sub').textContent = BOSS_WAVES[next] ? `Próxima: onda ${next}. Um chefe espera por você.` : `Próxima: onda ${next} de ${TOTAL_WAVES}`;
    this.$('shop-gold').textContent = gold;

    const wrap = this.$('shop-cards');
    wrap.innerHTML = '';
    game.shopOffers.forEach((offer, i) => {
      if (!offer) {
        const sold = document.createElement('div');
        sold.className = 'card sold';
        sold.textContent = 'Comprado';
        wrap.append(sold);
        return;
      }
      const card = this.makeCard(offer, i + 1, offer.price, gold >= offer.price);
      card.addEventListener('click', () => game.buy(i));
      wrap.append(card);
    });

    const cost = game.rerollCost();
    const reroll = this.$('btn-reroll');
    reroll.innerHTML = `Trocar ofertas <span class="coin"></span>${cost}`;
    reroll.classList.toggle('cant-afford', gold < cost);

    this.renderInventory(p, this.$('shop-weapons'), this.$('shop-items'));
    this.renderStats(this.$('shop-stats'), p);
  },

  renderInventory(p, weaponsEl, itemsEl) {
    weaponsEl.innerHTML = p.weapons.map(w => `<div class="inv-weapon"><span>${w.def.icon}</span><span>${w.def.name}</span><span class="muted">Nv ${w.level}</span></div>`).join('')
      + `<div class="muted small">${p.weapons.length}/${MAX_WEAPONS} espaços</div>`;
    if (!itemsEl) return;
    const counts = new Map();
    for (const it of p.items) counts.set(it, (counts.get(it) || 0) + 1);
    itemsEl.innerHTML = counts.size
      ? [...counts].map(([it, n]) => `<span class="inv-item" title="${it.name}">${it.icon}${n > 1 ? `<small>×${n}</small>` : ''}</span>`).join('')
      : '<span class="muted small">Nenhum item ainda</span>';
  },

  renderStats(dl, p) {
    dl.innerHTML = Object.keys(STAT_INFO).map(k => {
      const v = p.stats[k], base = BASE_STATS[k];
      const better = STAT_INFO[k].invert ? v < base : v > base;
      const worse = STAT_INFO[k].invert ? v > base : v < base;
      const cls = Math.abs(v - base) < 1e-6 ? '' : better ? 'good' : worse ? 'bad' : '';
      return `<div class="stat-row"><dt>${STAT_INFO[k].label}</dt><dd class="${cls}">${formatStatValue(k, v)}</dd></div>`;
    }).join('');
  },

  showPause(game) {
    this.quitArmed = false;
    this.$('btn-quit').textContent = 'Desistir da partida';
    this.renderStats(this.$('pause-stats'), game.player);
    this.renderInventory(game.player, this.$('pause-weapons'), null);
    this.updateMuteLabel();
    this.showScreen('pause');
  },

  updateMuteLabel() {
    this.$('btn-mute').textContent = Sfx.muted ? 'Som: desligado' : 'Som: ligado';
  },

  showEnd(game, victory) {
    const p = game.player;
    this.$('hud').hidden = true;
    this.hideBossBar();
    this.$('end-title').textContent = victory ? 'Vitória!' : 'Você caiu';
    this.$('end-sub').textContent = victory
      ? `${p.hero.name} derrotou A Calamidade e salvou o reino.`
      : `${p.hero.name} foi derrotado na onda ${game.wave}.`;
    this.$('screen-end').classList.toggle('victory', victory);
    const mins = Math.floor(game.runTime / 60), secs = Math.floor(game.runTime % 60);
    const rows = [
      ['Onda', `${game.wave} / ${TOTAL_WAVES}`],
      ['Nível', p.level],
      ['Inimigos derrotados', game.kills],
      ['Tempo', `${mins}:${String(secs).padStart(2, '0')}`],
      ['Armas', p.weapons.map(w => w.def.icon).join(' ')],
    ];
    this.$('end-stats').innerHTML = rows.map(([k, v]) => `<div class="stat-row"><dt>${k}</dt><dd>${v}</dd></div>`).join('');
    this.$('btn-retry').textContent = `Jogar de novo com ${p.hero.name}`;
    this.showScreen('end');
  },
};
