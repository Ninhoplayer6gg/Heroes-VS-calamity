'use strict';
// Núcleo do jogo: estados, ondas, spawn, combate, coleta e renderização
//
// Estados: menu → playing ⇄ (levelup | paused) → clear → shop → playing ... → dead/over | victory

const Game = {
  state: 'menu',
  canvas: null,
  ctx: null,
  dpr: 1,
  vw: 0,
  vh: 0,
  zoom: 1,
  camX: 0,
  camY: 0,
  shakeAmt: 0,
  time: 0,
  realTime: 0,

  hero: null,
  player: null,
  enemies: [],
  projectiles: [],
  enemyBullets: [],
  pickups: [],
  minions: [],
  effects: [],
  particles: [],
  texts: [],
  timers: [],
  spawnQueue: [],

  wave: 0,
  waveTime: 0,
  waveDuration: 0,
  isBossWave: false,
  boss: null,
  bossDefeated: false,
  spawnAcc: 0,
  eliteSpawned: false,
  waveEnded: false,
  clearTimer: 0,
  deadTimer: 0,
  pendingLevels: 0,
  kills: 0,
  runTime: 0,
  shopOffers: [],
  shopRerolls: 0,

  grid: null,
  floor: null,

  init() {
    this.canvas = document.getElementById('game');
    this.ctx = this.canvas.getContext('2d');
    this.grid = new SpatialGrid(ARENA.w, ARENA.h, 64);
    this.floor = Sprites.buildFloor();
    window.addEventListener('resize', () => this.resize());
    this.resize();
    this.camX = ARENA.w / 2 - this.vw / this.zoom / 2;
    this.camY = ARENA.h / 2 - this.vh / this.zoom / 2;
    Input.init(this.canvas);
    Input.onPause = () => this.togglePause();
    UI.init(this);
    document.addEventListener('visibilitychange', () => {
      if (document.hidden && this.state === 'playing') this.togglePause();
    });

    let last = performance.now();
    const loop = now => {
      const dt = Math.min(0.05, (now - last) / 1000);
      last = now;
      this.frame(dt);
      requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  },

  resize() {
    this.vw = window.innerWidth;
    this.vh = window.innerHeight;
    this.dpr = Math.min(window.devicePixelRatio || 1, 2);
    this.canvas.width = Math.round(this.vw * this.dpr);
    this.canvas.height = Math.round(this.vh * this.dpr);
    this.canvas.style.width = this.vw + 'px';
    this.canvas.style.height = this.vh + 'px';
    this.zoom = clamp(Math.min(this.vw, this.vh) / 680, 0.6, 1.3);
  },

  frame(dt) {
    this.realTime += dt;
    switch (this.state) {
      case 'playing':
        this.update(dt);
        break;
      case 'clear':
        this.updateClear(dt);
        break;
      case 'dead':
        this.updateFx(dt);
        this.deadTimer -= dt;
        if (this.deadTimer <= 0) {
          this.state = 'over';
          UI.showEnd(this, false);
        }
        break;
      case 'menu':
        this.updateMenuFx(dt);
        break;
    }
    this.render(dt);
    if (this.player && this.state !== 'menu') UI.updateHUD(this);
    if (this.state === 'menu') UI.animateMenu(this.realTime);
  },

  // ---------- Fluxo da partida ----------

  newRun(hero) {
    Sfx.unlock();
    this.hero = hero;
    this.player = new Player(hero);
    this.kills = 0;
    this.runTime = 0;
    this.time = 0;
    this.pendingLevels = 0;
    this.effects = [];
    this.particles = [];
    this.texts = [];
    this.startWave(1);
  },

  startWave(n) {
    this.wave = n;
    this.waveTime = 0;
    this.waveEnded = false;
    this.spawnAcc = 0;
    this.eliteSpawned = false;
    this.isBossWave = BOSS_WAVES[n] !== undefined;
    this.waveDuration = this.isBossWave ? Infinity : Math.min(20 + (n - 1) * 5, 60);
    this.boss = null;
    this.bossDefeated = false;
    this.enemies = [];
    this.projectiles = [];
    this.enemyBullets = [];
    this.pickups = [];
    this.minions = [];
    this.timers = [];
    this.spawnQueue = [];

    // Como no Brotato: a vida é restaurada no começo de cada onda
    const p = this.player;
    p.buffs = [];
    p.recalc();
    p.hp = p.stats.maxHp;
    p.x = ARENA.w / 2;
    p.y = ARENA.h / 2;
    p.invuln = 1;
    p.shield = 0;
    p.abilityTimer = 0;
    for (const w of p.weapons) w.timer = 0.3 + Math.random() * 0.4;

    this.state = 'playing';
    UI.showHUD();
    if (this.isBossWave) {
      this.schedule(1.5, () => this.spawnBoss(BOSS_WAVES[n]));
      UI.banner(`Onda ${n}`, n === TOTAL_WAVES ? 'A Calamidade despertou!' : 'Um chefe se aproxima!');
      Sfx.play('boss');
    } else {
      UI.banner(`Onda ${n}`, `Sobreviva por ${this.waveDuration} segundos`);
      Sfx.play('wave');
    }
  },

  endWave() {
    if (this.waveEnded) return;
    this.waveEnded = true;
    for (const e of this.enemies) {
      e.dead = true;
      this.burst(e.x, e.y, e.color, 5);
    }
    this.enemies = [];
    this.enemyBullets = [];
    this.spawnQueue = [];
    this.minions = [];
    this.timers = [];
    for (const pk of this.pickups) pk.magnet = true;
    this.state = 'clear';
    this.clearTimer = 1.4;
    this.player.moving = false;
    Input.reset();
    if (this.wave < TOTAL_WAVES) UI.banner('Onda concluída!', `${this.wave} de ${TOTAL_WAVES}`);
    Sfx.play('wave');
  },

  updateClear(dt) {
    this.time += dt;
    for (const pk of this.pickups) pk.update(dt, this);
    this.pickups = this.pickups.filter(pk => !pk.dead);
    this.updateFx(dt);
    this.clearTimer -= dt;
    if (this.clearTimer > 0) return;
    for (const pk of this.pickups) this.collect(pk, true);
    this.pickups = [];
    this.saveRecord();
    if (this.wave >= TOTAL_WAVES) {
      this.state = 'victory';
      Sfx.play('victory');
      UI.showEnd(this, true);
    } else if (this.pendingLevels > 0) this.openLevelUp();
    else this.openShop();
  },

  openLevelUp() {
    this.state = 'levelup';
    Input.reset();
    Sfx.play('levelup');
    const p = this.player;
    UI.openLevelUp(p.level - this.pendingLevels + 1, rollLevelUpOptions(p, this.wave), opt => this.chooseLevelUp(opt));
  },

  chooseLevelUp(opt) {
    opt.apply(this.player);
    this.pendingLevels--;
    if (this.pendingLevels > 0) this.openLevelUp();
    else if (this.waveEnded) this.openShop();
    else {
      this.state = 'playing';
      UI.hideScreens();
    }
  },

  openShop() {
    this.state = 'shop';
    this.shopRerolls = 0;
    this.shopOffers = rollShopOffers(this.player, this.wave + 1);
    UI.openShop(this);
  },

  rerollCost() { return Math.ceil(2 + this.wave * 0.8) + this.shopRerolls * 2; },

  buy(i) {
    const offer = this.shopOffers[i];
    const p = this.player;
    if (!offer) return;
    if (Math.floor(p.gold) < offer.price) {
      Sfx.play('deny');
      return;
    }
    if (offer.kind === 'weapon' && !p.getWeapon(offer.key.slice(7)) && p.weapons.length >= MAX_WEAPONS) {
      Sfx.play('deny');
      return;
    }
    p.gold -= offer.price;
    offer.apply(p);
    this.shopOffers[i] = null;
    Sfx.play('buy');
    UI.openShop(this);
  },

  reroll() {
    const cost = this.rerollCost();
    const p = this.player;
    if (Math.floor(p.gold) < cost) {
      Sfx.play('deny');
      return;
    }
    p.gold -= cost;
    this.shopRerolls++;
    this.shopOffers = rollShopOffers(p, this.wave + 1);
    Sfx.play('buy');
    UI.openShop(this);
  },

  nextWave() {
    UI.hideScreens();
    this.startWave(this.wave + 1);
  },

  togglePause() {
    if (this.state === 'playing') {
      this.state = 'paused';
      Input.reset();
      UI.showPause(this);
    } else if (this.state === 'paused') {
      this.state = 'playing';
      UI.hideScreens();
    }
  },

  quitToMenu() {
    this.saveRecord();
    this.state = 'menu';
    this.player = null;
    this.enemies = [];
    this.projectiles = [];
    this.enemyBullets = [];
    this.pickups = [];
    this.minions = [];
    this.timers = [];
    this.spawnQueue = [];
    this.effects = [];
    this.texts = [];
    UI.showMenu();
  },

  onPlayerDeath() {
    const p = this.player;
    if (p.revives > 0) {
      p.revives--;
      p.hp = p.stats.maxHp * 0.5;
      p.invuln = 2.5;
      p.shield = 2.5;
      this.damageArea(p.x, p.y, 260, 80 * this.abilityScale(), { knockback: 800 });
      this.addEffect(new RingEffect(p.x, p.y, 260, '#ff9f1a', 0.6, 10));
      this.burst(p.x, p.y, '#ff9f1a', 40, 300);
      this.addText(p.x, p.y - 40, 'Renasceu!', '#ff9f1a', 26);
      UI.toast('🪶 A Pena de Fênix te trouxe de volta!');
      return;
    }
    p.hp = 0;
    this.state = 'dead';
    this.deadTimer = 1.5;
    this.burst(p.x, p.y, p.hero.color, 50, 320);
    this.shake(14);
    Sfx.play('death');
    this.saveRecord();
  },

  saveRecord() {
    if (!this.hero) return;
    const rec = storageGet('hvc-records', {});
    const reached = this.state === 'victory' ? TOTAL_WAVES + 1 : this.wave;
    if (!rec[this.hero.id] || rec[this.hero.id] < reached) {
      rec[this.hero.id] = reached;
      storageSet('hvc-records', rec);
    }
  },

  // ---------- Escala de dificuldade ----------

  hpScale(w) { return 1 + (w - 1) * 0.22 + (w - 1) ** 2 * 0.018; },
  dmgScale(w) { return 1 + (w - 1) * 0.09; },
  abilityScale() { return 1 + (this.wave - 1) * 0.15; },

  // ---------- Atualização principal ----------

  update(dt) {
    this.time += dt;
    this.runTime += dt;
    this.waveTime += dt;

    this.grid.clear();
    for (const e of this.enemies) if (!e.dead) this.grid.insert(e);

    if (this.timers.length) {
      const due = [];
      for (const t of this.timers) {
        t.at -= dt;
        if (t.at <= 0) due.push(t);
      }
      if (due.length) {
        this.timers = this.timers.filter(t => t.at > 0);
        for (const t of due) t.fn();
      }
    }

    const p = this.player;
    p.update(dt, this);

    this.updateSpawning(dt);
    for (const e of this.enemies) if (!e.dead) e.update(dt, this);
    this.separateEnemies();

    // contato inimigo → jogador
    for (const e of this.enemies) {
      if (e.dead) continue;
      const rr = e.r + p.r - 4;
      if (dist2(e.x, e.y, p.x, p.y) < rr * rr) p.takeDamage(e.damage, this);
    }

    // projéteis do jogador
    for (const pr of this.projectiles) {
      pr.update(dt, this);
      if (pr.dead) continue;
      this.grid.query(pr.x, pr.y, pr.r + 70, e => {
        if (pr.dead || e.dead || pr.hit.has(e)) return;
        const rr = pr.r + e.r;
        if (dist2(pr.x, pr.y, e.x, e.y) <= rr * rr) this.projectileHit(pr, e);
      });
    }

    // projéteis inimigos
    for (const b of this.enemyBullets) {
      b.life -= dt;
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      if (b.life <= 0 || b.x < -20 || b.x > ARENA.w + 20 || b.y < -20 || b.y > ARENA.h + 20) {
        b.dead = true;
        continue;
      }
      const rr = b.r + p.r - 3;
      if (dist2(b.x, b.y, p.x, p.y) < rr * rr) {
        b.dead = true;
        p.takeDamage(b.damage, this);
      }
    }

    for (const m of this.minions) m.update(dt, this);
    for (const pk of this.pickups) pk.update(dt, this);
    this.updateFx(dt);

    this.enemies = this.enemies.filter(e => !e.dead);
    this.projectiles = this.projectiles.filter(pr => !pr.dead);
    this.enemyBullets = this.enemyBullets.filter(b => !b.dead);
    this.minions = this.minions.filter(m => !m.dead);
    this.pickups = this.pickups.filter(pk => !pk.dead);

    if (this.state !== 'playing') return;
    if (!this.isBossWave && this.waveTime >= this.waveDuration) this.endWave();
    else if (this.pendingLevels > 0) this.openLevelUp();
  },

  updateFx(dt) {
    this.effects = this.effects.filter(fx => fx.update(dt));
    for (const pt of this.particles) {
      pt.life -= dt;
      pt.x += pt.vx * dt;
      pt.y += pt.vy * dt;
      pt.vx *= 0.94;
      pt.vy *= 0.94;
    }
    this.particles = this.particles.filter(pt => pt.life > 0);
    this.texts = this.texts.filter(t => t.update(dt));
    if (this.spawnQueue.length) {
      for (const s of this.spawnQueue) s.t -= dt;
      const ready = this.spawnQueue.filter(s => s.t <= 0);
      if (ready.length) {
        this.spawnQueue = this.spawnQueue.filter(s => s.t > 0);
        for (const s of ready) this.enemies.push(new Enemy(ENEMY_TYPES[s.type], s.x, s.y, this.wave, s.elite));
      }
    }
  },

  updateMenuFx(dt) {
    if (Math.random() < dt * 30) {
      const viewW = this.vw / this.zoom, viewH = this.vh / this.zoom;
      this.particle(this.camX + rand(0, viewW), this.camY + viewH + 10, rand(-15, 15), rand(-90, -40), rand(3, 6), chance(0.7) ? '#ff6a3d' : '#ffd23f', rand(2, 4));
    }
    this.updateFx(dt);
  },

  // ---------- Spawn ----------

  updateSpawning(dt) {
    if (this.isBossWave && (this.bossDefeated || !this.boss)) return;
    const w = this.wave;
    const ramp = 0.7 + 0.6 * Math.min(1, this.waveTime / Math.min(this.waveDuration, 60));
    let rate = (0.9 + w * 0.38) * ramp;
    if (this.isBossWave) rate *= 0.45;
    this.spawnAcc += rate * dt;
    while (this.spawnAcc >= 1) {
      const size = Math.min(Math.floor(this.spawnAcc), randInt(1, 1 + Math.floor(w / 4)));
      this.spawnAcc -= size;
      this.queueGroup(size);
    }
    // Elite com baú a cada 3 ondas
    if (!this.isBossWave && w % 3 === 0 && !this.eliteSpawned && this.waveTime > this.waveDuration * 0.35) {
      this.eliteSpawned = true;
      this.queueGroup(1, true);
    }
  },

  pickEnemyType() {
    const w = this.wave;
    const entries = Object.values(ENEMY_TYPES)
      .filter(d => w >= d.minWave)
      .map(d => ({ id: d.id, weight: d.weight(w) }));
    return weightedPick(entries).id;
  },

  randomSpawnPoint() {
    const p = this.player;
    let x = 0, y = 0;
    for (let i = 0; i < 14; i++) {
      x = rand(60, ARENA.w - 60);
      y = rand(60, ARENA.h - 60);
      if (dist2(x, y, p.x, p.y) > 300 * 300) break;
    }
    return { x, y };
  },

  queueGroup(size, elite = false, type = null, at = null) {
    if (this.enemies.length + this.spawnQueue.length >= MAX_ENEMIES) return;
    const t = type || this.pickEnemyType();
    const pos = at || this.randomSpawnPoint();
    for (let i = 0; i < size; i++) {
      this.spawnQueue.push({
        x: clamp(pos.x + (size > 1 ? rand(-45, 45) : 0), 30, ARENA.w - 30),
        y: clamp(pos.y + (size > 1 ? rand(-45, 45) : 0), 30, ARENA.h - 30),
        type: t,
        elite,
        t: 0.9,
      });
    }
  },

  spawnBoss(key) {
    const def = BOSSES[key];
    const p = this.player;
    const y = p.y > ARENA.h / 2 ? 220 : ARENA.h - 220;
    const b = new Boss(def, ARENA.w / 2, y);
    this.boss = b;
    this.enemies.push(b);
    this.addEffect(new RingEffect(b.x, b.y, 220, '#ff3d2e', 0.8, 12));
    this.burst(b.x, b.y, '#ff3d2e', 40, 300);
    this.shake(12);
    UI.showBossBar(def.name);
  },

  separateEnemies() {
    const g = this.grid;
    for (const e of this.enemies) {
      if (e.dead || e.boss || e.def.behavior === 'phase') continue;
      g.query(e.x, e.y, e.r + 64, o => {
        if (o === e || o.dead || o.def.behavior === 'phase') return;
        const dx = e.x - o.x, dy = e.y - o.y;
        const min = e.r + o.r;
        const d2 = dx * dx + dy * dy;
        if (d2 < min * min && d2 > 0.0001) {
          const d = Math.sqrt(d2);
          const push = (min - d) * (o.boss ? 1 : 0.5);
          e.x += (dx / d) * push;
          e.y += (dy / d) * push;
        }
      });
    }
  },

  // ---------- Combate ----------

  hitEnemy(e, base, opts = {}) {
    if (e.dead) return 0;
    const p = this.player;
    const crit = Math.random() < p.stats.crit;
    let dmg = base * p.stats.damage * (crit ? p.stats.critMult : 1);
    dmg = Math.max(1, Math.round(dmg * rand(0.9, 1.1)));
    e.hp -= dmg;
    e.flash = 0.08;
    if (opts.knockback) {
      const a = opts.angle !== undefined ? opts.angle : angleTo(p.x, p.y, e.x, e.y);
      const kb = opts.knockback * (1 - e.kbResist);
      e.kx += Math.cos(a) * kb;
      e.ky += Math.sin(a) * kb;
    }
    this.addText(e.x, e.y - e.r, dmg, crit ? '#ffd23f' : '#ffffff', crit ? 19 : 14);
    if (p.stats.lifesteal > 0 && Math.random() < p.stats.lifesteal) p.heal(1);
    Sfx.play('hit');
    if (e.hp <= 0) this.killEnemy(e);
    return dmg;
  },

  damageArea(x, y, r, dmg, opts = {}) {
    let n = 0;
    this.grid.query(x, y, r + 70, e => {
      if (e.dead) return;
      const rr = r + e.r;
      if (dist2(x, y, e.x, e.y) <= rr * rr) {
        this.hitEnemy(e, dmg, { ...opts, angle: angleTo(x, y, e.x, e.y) });
        n++;
      }
    });
    return n;
  },

  coneDamage(x, y, range, angle, arc, dmg, opts = {}) {
    for (const e of this.enemies) {
      if (e.dead) continue;
      const d = dist(x, y, e.x, e.y) - e.r;
      if (d > range) continue;
      const a = angleTo(x, y, e.x, e.y);
      if (d < 20 || Math.abs(normAngle(a - angle)) <= arc / 2) this.hitEnemy(e, dmg, { ...opts, angle: a });
    }
  },

  projectileHit(pr, e) {
    pr.hit.add(e);
    if (pr.explode) {
      this.damageArea(pr.x, pr.y, pr.explode, pr.damage, { knockback: 180 });
      this.explosion(pr.x, pr.y, pr.explode, pr.color);
      pr.dead = true;
      return;
    }
    this.hitEnemy(e, pr.damage, { knockback: pr.knockback, angle: Math.atan2(pr.vy, pr.vx) });
    if (pr.bounces > 0) {
      const next = this.nearestEnemy(pr.x, pr.y, 260, pr.hit);
      if (next) {
        pr.bounces--;
        const sp = Math.hypot(pr.vx, pr.vy);
        const a = angleTo(pr.x, pr.y, next.x, next.y);
        pr.vx = Math.cos(a) * sp;
        pr.vy = Math.sin(a) * sp;
        pr.life = Math.max(pr.life, 0.8);
        return;
      }
    }
    if (pr.pierce > 0) {
      pr.pierce--;
      return;
    }
    pr.dead = true;
  },

  killEnemy(e) {
    if (e.dead) return;
    e.dead = true;
    this.kills++;
    this.burst(e.x, e.y, e.color, e.boss ? 80 : 8);
    Sfx.play('kill');
    const p = this.player;

    if (e.boss) {
      this.bossDefeated = true;
      this.boss = null;
      UI.hideBossBar();
      this.explosion(e.x, e.y, 200, '#ff6a3d');
      this.shake(18);
      for (let i = 0; i < 30; i++) this.pickups.push(new Pickup('gem', e.x + rand(-60, 60), e.y + rand(-60, 60), Math.max(1, Math.round(e.xp / 10)), 2));
      if (this.wave < TOTAL_WAVES) this.pickups.push(new Pickup('chest', e.x, e.y));
      for (const o of this.enemies) if (!o.dead && !o.boss) this.killEnemy(o);
      this.schedule(1.6, () => this.endWave());
      return;
    }

    if (e.elite) {
      for (let i = 0; i < 6; i++) this.pickups.push(new Pickup('gem', e.x, e.y, Math.round(e.xp / 6), 2));
      this.pickups.push(new Pickup('chest', e.x, e.y));
    } else {
      this.dropGem(e.x, e.y, e.xp, 1);
    }
    if (Math.random() < 0.012 + p.stats.luck * 0.0004) this.pickups.push(new Pickup('heart', e.x, e.y));
  },

  dropGem(x, y, value, gold) {
    // Muitas gemas no chão: junta o valor numa gema existente para poupar desempenho
    if (this.pickups.length > 320) {
      const g = this.pickups[Math.floor(Math.random() * this.pickups.length)];
      if (g.kind === 'gem') {
        g.value += value;
        g.gold += gold;
        return;
      }
    }
    this.pickups.push(new Pickup('gem', x, y, value, gold));
  },

  collect(pk, silent = false) {
    const p = this.player;
    switch (pk.kind) {
      case 'gem':
        this.gainXp(pk.value);
        p.gold += pk.gold * p.stats.goldGain;
        if (!silent) Sfx.play('pickup');
        break;
      case 'heart':
        p.heal(p.stats.maxHp * 0.2);
        break;
      case 'chest': {
        const item = rollChestItem(p, this.wave);
        p.addItem(item);
        UI.toast(`Baú: ${item.icon} ${item.name}`);
        this.addText(p.x, p.y - 40, item.name, '#f2c14e', 18);
        Sfx.play('chest');
        break;
      }
    }
  },

  gainXp(v) {
    const p = this.player;
    p.xp += v * p.stats.xpGain;
    let need = p.xpToNext();
    while (p.xp >= need) {
      p.xp -= need;
      p.level++;
      this.pendingLevels++;
      need = p.xpToNext();
    }
  },

  // ---------- Consultas e criação ----------

  // O chefe conta como 150px mais perto, para as armas priorizarem ele
  nearestEnemy(x, y, maxR, exclude = null) {
    let best = null, bestD = maxR * maxR;
    for (const e of this.enemies) {
      if (e.dead || (exclude && exclude.has(e))) continue;
      let d = dist2(x, y, e.x, e.y);
      if (e.boss) d = Math.max(0, Math.sqrt(d) - 150) ** 2;
      if (d < bestD) {
        bestD = d;
        best = e;
      }
    }
    return best;
  },

  randomEnemy(x, y, maxR, exclude = null) {
    const r2 = maxR * maxR;
    const list = this.enemies.filter(e => !e.dead && !(exclude && exclude.has(e)) && dist2(x, y, e.x, e.y) < r2);
    return list.length ? pick(list) : null;
  },

  addProjectile(o) { this.projectiles.push(new Projectile(o)); },
  addEffect(fx) { this.effects.push(fx); },
  addMinion(m) { this.minions.push(m); },
  schedule(delay, fn) { this.timers.push({ at: delay, fn }); },

  addText(x, y, text, color, size) {
    if (this.texts.length > 80) this.texts.shift();
    this.texts.push(new FloatText(x, y, text, color, size));
  },

  enemyShoot(x, y, a, speed, damage, color) {
    this.enemyBullets.push({ x, y, vx: Math.cos(a) * speed, vy: Math.sin(a) * speed, r: 7, damage, life: 5, color, dead: false });
  },

  particle(x, y, vx, vy, life, color, size) {
    if (this.particles.length > 700) return;
    this.particles.push({ x, y, vx, vy, life, max: life, color, size });
  },

  burst(x, y, color, n = 8, speed = 170) {
    for (let i = 0; i < n; i++) {
      const a = rand(0, TAU), s = rand(speed * 0.3, speed);
      this.particle(x, y, Math.cos(a) * s, Math.sin(a) * s, rand(0.25, 0.6), color, rand(3, 6));
    }
  },

  explosion(x, y, r, color) {
    this.addEffect(new ExplosionEffect(x, y, r, color));
    this.burst(x, y, color, 10, r * 3);
    Sfx.play('explode');
  },

  shake(a) {
    if (REDUCED_MOTION) return;
    this.shakeAmt = Math.max(this.shakeAmt, a);
  },

  // ---------- Renderização ----------

  render(dt) {
    const ctx = this.ctx;
    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    ctx.fillStyle = '#07050a';
    ctx.fillRect(0, 0, this.vw, this.vh);

    const z = this.zoom;
    const viewW = this.vw / z, viewH = this.vh / z;
    const p = this.player;
    let tx, ty;
    if (p && this.state !== 'menu') {
      tx = p.x - viewW / 2;
      ty = p.y - viewH / 2;
    } else {
      tx = ARENA.w / 2 - viewW / 2 + Math.sin(this.realTime * 0.12) * 260;
      ty = ARENA.h / 2 - viewH / 2 + Math.cos(this.realTime * 0.09) * 160;
    }
    tx = viewW > ARENA.w + 160 ? (ARENA.w - viewW) / 2 : clamp(tx, -80, ARENA.w - viewW + 80);
    ty = viewH > ARENA.h + 160 ? (ARENA.h - viewH) / 2 : clamp(ty, -80, ARENA.h - viewH + 80);
    const follow = 1 - Math.exp(-dt * 10);
    this.camX = lerp(this.camX, tx, follow);
    this.camY = lerp(this.camY, ty, follow);

    let sx = 0, sy = 0;
    if (this.shakeAmt > 0.2) {
      sx = rand(-1, 1) * this.shakeAmt;
      sy = rand(-1, 1) * this.shakeAmt;
      this.shakeAmt *= Math.exp(-dt * 12);
    } else this.shakeAmt = 0;

    ctx.save();
    ctx.scale(z, z);
    ctx.translate(-this.camX + sx, -this.camY + sy);

    // chão (apenas a parte visível)
    const f = this.floor;
    const srcX = clamp(this.camX + f.margin - 20, 0, f.canvas.width);
    const srcY = clamp(this.camY + f.margin - 20, 0, f.canvas.height);
    const srcW = Math.min(viewW + 40, f.canvas.width - srcX);
    const srcH = Math.min(viewH + 40, f.canvas.height - srcY);
    if (srcW > 0 && srcH > 0) ctx.drawImage(f.canvas, srcX, srcY, srcW, srcH, srcX - f.margin, srcY - f.margin, srcW, srcH);

    const t = this.time;

    // marcadores de spawn
    for (const s of this.spawnQueue) {
      const a = 0.4 + 0.4 * Math.sin(s.t * 20);
      ctx.strokeStyle = s.elite ? `rgba(242, 193, 78, ${a})` : `rgba(255, 70, 60, ${a})`;
      ctx.lineWidth = 3;
      const k = 9;
      ctx.beginPath();
      ctx.moveTo(s.x - k, s.y - k);
      ctx.lineTo(s.x + k, s.y + k);
      ctx.moveTo(s.x + k, s.y - k);
      ctx.lineTo(s.x - k, s.y + k);
      ctx.stroke();
    }

    for (const pk of this.pickups) Sprites.pickup(ctx, pk, t);

    if (p && this.state !== 'menu') {
      for (const w of p.weapons) if (w.def.drawUnder) w.def.drawUnder(ctx, this, p, w, w.stats);
    }

    const px = p ? p.x : 0;
    Sprites.shadows(ctx, this.enemies);
    for (const e of this.enemies) e.draw(ctx, t, px);
    for (const m of this.minions) Sprites.skeleton(ctx, m, t);
    if (p && this.state !== 'menu' && this.state !== 'dead' && this.state !== 'over') {
      p.draw(ctx, t);
      for (const w of p.weapons) if (w.def.draw) w.def.draw(ctx, this, p, w);
    }
    for (const pr of this.projectiles) Sprites.projectile(ctx, pr);
    for (const b of this.enemyBullets) Sprites.enemyBullet(ctx, b);
    for (const fx of this.effects) fx.draw(ctx);

    for (const pt of this.particles) {
      ctx.globalAlpha = clamp(pt.life / pt.max, 0, 1);
      ctx.fillStyle = pt.color;
      const s = pt.size;
      ctx.fillRect(pt.x - s / 2, pt.y - s / 2, s, s);
    }
    ctx.globalAlpha = 1;

    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    let font = 0;
    for (const ft of this.texts) {
      if (ft.size !== font) {
        font = ft.size;
        ctx.font = `700 ${font}px 'Barlow Semi Condensed', 'Arial Narrow', sans-serif`;
      }
      ft.draw(ctx);
    }

    ctx.restore();

    if (this.boss && !this.boss.dead) this.drawOffscreenArrow(ctx, this.boss);
    Input.drawJoystick(ctx);
  },

  drawOffscreenArrow(ctx, target) {
    const z = this.zoom;
    const sx = (target.x - this.camX) * z, sy = (target.y - this.camY) * z;
    const m = 40;
    if (sx > -target.r * z && sx < this.vw + target.r * z && sy > -target.r * z && sy < this.vh + target.r * z) return;
    const cx = this.vw / 2, cy = this.vh / 2;
    const a = Math.atan2(sy - cy, sx - cx);
    const ax = clamp(sx, m, this.vw - m), ay = clamp(sy, m + 60, this.vh - m - 60);
    ctx.save();
    ctx.translate(ax, ay);
    ctx.rotate(a);
    ctx.fillStyle = '#ff3d2e';
    ctx.beginPath();
    ctx.moveTo(16, 0);
    ctx.lineTo(-10, -11);
    ctx.lineTo(-10, 11);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  },
};
