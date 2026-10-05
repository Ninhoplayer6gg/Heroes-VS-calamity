'use strict';
// Entidades: jogador, inimigos, chefes, projéteis, coletáveis, lacaios e efeitos visuais

// Atributos base de todo herói. Itens, níveis e heróis somam modificadores a estes valores.
const BASE_STATS = {
  maxHp: 100,
  regen: 0,          // vida por segundo
  armor: 0,          // reduz dano recebido
  speed: 1,          // multiplicador de velocidade de movimento
  damage: 1,         // multiplicador de dano
  attackSpeed: 1,    // multiplicador de velocidade de ataque
  crit: 0.05,        // chance de crítico
  critMult: 1.75,
  area: 1,           // multiplicador de área/raio
  projectiles: 0,    // projéteis extras
  pickupRange: 90,   // alcance do ímã em pixels
  dodge: 0,          // chance de esquiva
  lifesteal: 0,      // chance de curar 1 de vida ao acertar
  cooldown: 1,       // multiplicador da recarga da habilidade
  xpGain: 1,
  goldGain: 1,
  luck: 0,
};

class Weapon {
  constructor(def) {
    this.def = def;
    this.level = 1;
    this.timer = 0.2 + Math.random() * 0.3;
    this.data = {};
  }

  get stats() { return this.def.stats(this.level); }
}

class Player {
  constructor(hero) {
    this.hero = hero;
    this.x = ARENA.w / 2;
    this.y = ARENA.h / 2;
    this.r = 17;
    this.mods = [];
    this.buffs = [];
    this.items = [];
    this.weapons = [];
    this.stats = { ...BASE_STATS };
    this.level = 1;
    this.xp = 0;
    this.gold = 0;
    this.invuln = 0;
    this.hurtFlash = 0;
    this.shield = 0;
    this.facing = 1;
    this.dirX = 1;
    this.dirY = 0;
    this.moving = false;
    this.abilityTimer = 0;
    this.revives = 0;
    this.animT = 0;
    if (hero.mods) this.mods.push(hero.mods);
    this.recalc();
    this.hp = this.stats.maxHp;
    this.addWeapon(hero.startWeapon);
  }

  recalc() {
    const s = { ...BASE_STATS };
    const apply = m => { for (const k in m) s[k] = (s[k] || 0) + m[k]; };
    this.mods.forEach(apply);
    this.buffs.forEach(b => apply(b.mods));
    s.maxHp = Math.max(1, Math.round(s.maxHp));
    s.speed = Math.max(0.4, s.speed);
    s.damage = Math.max(0.1, s.damage);
    s.attackSpeed = Math.max(0.3, s.attackSpeed);
    s.crit = clamp(s.crit, 0, 1);
    s.area = Math.max(0.3, s.area);
    s.projectiles = Math.max(0, Math.round(s.projectiles));
    s.pickupRange = Math.max(30, s.pickupRange);
    s.dodge = clamp(s.dodge, 0, 0.6);
    s.lifesteal = clamp(s.lifesteal, 0, 0.5);
    s.cooldown = Math.max(0.3, s.cooldown);
    s.xpGain = Math.max(0.1, s.xpGain);
    s.goldGain = Math.max(0.1, s.goldGain);
    const prevMax = this.stats.maxHp;
    this.stats = s;
    if (this.hp !== undefined) {
      if (s.maxHp > prevMax) this.hp += s.maxHp - prevMax;
      this.hp = Math.min(this.hp, s.maxHp);
    }
  }

  addMods(mods) {
    this.mods.push(mods);
    this.recalc();
  }

  addBuff(id, mods, duration) {
    this.buffs = this.buffs.filter(b => b.id !== id);
    this.buffs.push({ id, mods, time: duration });
    this.recalc();
  }

  hasBuff(id) { return this.buffs.some(b => b.id === id); }

  getWeapon(id) { return this.weapons.find(w => w.def.id === id); }

  addWeapon(id) {
    const existing = this.getWeapon(id);
    if (existing) {
      existing.level = Math.min(existing.level + 1, existing.def.maxLevel);
      return existing;
    }
    if (this.weapons.length >= MAX_WEAPONS) return null;
    const w = new Weapon(WEAPONS[id]);
    this.weapons.push(w);
    return w;
  }

  addItem(item) {
    this.items.push(item);
    if (item.special === 'revive') this.revives++;
    this.addMods(item.mods);
  }

  xpToNext() { return Math.round((this.level + 3) ** 2 * 0.8); }

  get abilityCooldown() { return this.hero.ability.cooldown * this.stats.cooldown; }

  update(dt, game) {
    const mv = Input.getMove();
    this.moving = mv.x !== 0 || mv.y !== 0;
    if (this.moving) {
      const l = Math.hypot(mv.x, mv.y);
      this.dirX = mv.x / l;
      this.dirY = mv.y / l;
      if (Math.abs(mv.x) > 0.15) this.facing = Math.sign(mv.x);
    }
    const sp = BASE_MOVE_SPEED * this.stats.speed;
    this.x = clamp(this.x + mv.x * sp * dt, this.r, ARENA.w - this.r);
    this.y = clamp(this.y + mv.y * sp * dt, this.r, ARENA.h - this.r);
    this.animT += dt;

    if (this.stats.regen > 0) this.heal(this.stats.regen * dt, true);

    if (this.buffs.length) {
      let expired = false;
      for (const b of this.buffs) {
        b.time -= dt;
        if (b.time <= 0) expired = true;
      }
      if (expired) {
        this.buffs = this.buffs.filter(b => b.time > 0);
        this.recalc();
      }
    }

    this.invuln = Math.max(0, this.invuln - dt);
    this.shield = Math.max(0, this.shield - dt);
    this.hurtFlash = Math.max(0, this.hurtFlash - dt);
    this.abilityTimer = Math.max(0, this.abilityTimer - dt);

    if (this.abilityTimer <= 0 && Input.isAbilityDown()) {
      this.hero.ability.cast(game, this);
      this.abilityTimer = this.abilityCooldown;
      Sfx.play('ability');
    }

    for (const w of this.weapons) {
      const s = w.stats;
      if (w.def.update) w.def.update(game, this, w, s, dt);
      if (w.def.fire) {
        w.timer -= dt * this.stats.attackSpeed;
        if (w.timer <= 0) w.timer = w.def.fire(game, this, w, s) ? s.cooldown : 0.1;
      }
    }
  }

  takeDamage(amount, game) {
    if (this.invuln > 0 || game.state !== 'playing') return false;
    if (Math.random() < this.stats.dodge) {
      game.addText(this.x, this.y - 26, 'Esquiva!', '#9fd8ff', 15);
      this.invuln = 0.25;
      return false;
    }
    const a = this.stats.armor;
    const factor = a >= 0 ? 15 / (15 + a) : 1 + -a / 15;
    const dmg = Math.max(1, Math.round(amount * factor));
    this.hp -= dmg;
    this.invuln = 0.45;
    this.hurtFlash = 0.2;
    game.addText(this.x, this.y - 28, '-' + dmg, '#ff5d5d', 19);
    game.shake(5);
    Sfx.play('hurt');
    if (this.hp <= 0) game.onPlayerDeath();
    return true;
  }

  heal(amount, silent = false) {
    if (this.hp >= this.stats.maxHp || amount <= 0) return;
    const before = this.hp;
    this.hp = Math.min(this.stats.maxHp, this.hp + amount);
    const gained = Math.round(this.hp - before);
    if (!silent && gained >= 1) Game.addText(this.x, this.y - 30, '+' + gained, '#7ee08a', 16);
  }

  draw(ctx, t) {
    const blink = this.invuln > 0 && this.shield <= 0 && Math.floor(t * 14) % 2 === 0;
    if (this.hasBuff('rage')) {
      ctx.fillStyle = 'rgba(255, 60, 60, 0.22)';
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.r * 1.9 + Math.sin(t * 14) * 3, 0, TAU);
      ctx.fill();
    }
    ctx.globalAlpha = blink ? 0.45 : 1;
    Sprites.hero(ctx, this.hero, this.x, this.y, this.r, this.facing, this.animT, { moving: this.moving, flash: this.hurtFlash > 0 });
    ctx.globalAlpha = 1;
    if (this.shield > 0) {
      const a = Math.min(1, this.shield) * 0.8;
      ctx.strokeStyle = `rgba(207, 224, 255, ${a})`;
      ctx.fillStyle = `rgba(150, 190, 255, ${a * 0.2})`;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.r * 1.75 + Math.sin(t * 8) * 1.5, 0, TAU);
      ctx.fill();
      ctx.stroke();
    }
  }
}

class Enemy {
  constructor(def, x, y, wave, elite = false) {
    this.def = def;
    this.x = x;
    this.y = y;
    this.elite = elite;
    this.boss = false;
    this.maxHp = def.hp * Game.hpScale(wave) * (elite ? 7 : 1);
    this.hp = this.maxHp;
    this.damage = def.damage * Game.dmgScale(wave) * (elite ? 1.3 : 1);
    this.speed = def.speed * (1 + (wave - 1) * 0.012) * rand(0.9, 1.1);
    this.r = def.radius * (elite ? 1.45 : 1);
    this.xp = def.xp * (elite ? 12 : 1);
    this.color = def.color;
    this.kbResist = elite ? Math.max(def.kbResist || 0, 0.6) : def.kbResist || 0;
    this.kx = 0;
    this.ky = 0;
    this.flash = 0;
    this.t = Math.random() * 10;
    this.state = 'move';
    this.stateT = rand(1.5, 3.5);
    this.shootT = rand(1, def.shootCooldown || 2);
    this.strafe = chance(0.5) ? 1 : -1;
    this.chargeA = 0;
    this.orbitHit = -9;
    this.dead = false;
  }

  update(dt, game) {
    this.t += dt;
    this.flash = Math.max(0, this.flash - dt);
    const p = game.player;
    const dx = p.x - this.x, dy = p.y - this.y;
    const d = Math.hypot(dx, dy) || 1;
    const nx = dx / d, ny = dy / d;
    let mx = nx, my = ny, sp = this.speed;

    switch (this.def.behavior) {
      case 'zigzag': {
        const w = Math.sin(this.t * 5) * 0.9;
        mx = nx - ny * w;
        my = ny + nx * w;
        break;
      }
      case 'ranged': {
        if (d < 200) { mx = -nx; my = -ny; }
        else if (d < 300) { mx = -ny * 0.6 * this.strafe; my = nx * 0.6 * this.strafe; }
        this.shootT -= dt;
        if (this.shootT <= 0 && d < 500) {
          this.shootT = this.def.shootCooldown * rand(0.8, 1.2);
          game.enemyShoot(this.x, this.y, Math.atan2(dy, dx), this.def.bulletSpeed, this.damage * 0.85, '#d64570');
        }
        break;
      }
      case 'bomber': {
        if (this.state === 'fuse') {
          sp = 0;
          this.stateT -= dt;
          if (this.stateT <= 0) this.explode(game);
        } else if (d < 55 + this.r) {
          this.state = 'fuse';
          this.stateT = 0.55;
        }
        break;
      }
      case 'charger': {
        if (this.state === 'move') {
          this.stateT -= dt;
          if (this.stateT <= 0 && d < 430) {
            this.state = 'aim';
            this.stateT = 0.65;
          }
        } else if (this.state === 'aim') {
          sp = 0;
          if (this.stateT > 0.25) this.chargeA = Math.atan2(dy, dx);
          this.stateT -= dt;
          if (this.stateT <= 0) { this.state = 'charge'; this.stateT = 0.55; }
        } else {
          mx = Math.cos(this.chargeA);
          my = Math.sin(this.chargeA);
          sp = this.speed * 7;
          this.stateT -= dt;
          if (Math.random() < 0.5) game.particle(this.x, this.y + this.r * 0.8, rand(-30, 30), rand(-40, -10), 0.4, '#5a4a3f', 4);
          if (this.stateT <= 0) { this.state = 'move'; this.stateT = rand(2.5, 4); }
        }
        break;
      }
    }

    this.x += (mx * sp + this.kx) * dt;
    this.y += (my * sp + this.ky) * dt;
    const decay = Math.exp(-dt * 9);
    this.kx *= decay;
    this.ky *= decay;
    this.x = clamp(this.x, this.r, ARENA.w - this.r);
    this.y = clamp(this.y, this.r, ARENA.h - this.r);
  }

  explode(game) {
    const R = 80;
    game.explosion(this.x, this.y, R, '#ff8c2a');
    const p = game.player;
    if (dist2(this.x, this.y, p.x, p.y) < (R + p.r) ** 2) p.takeDamage(this.damage, game);
    this.dead = true;
  }

  draw(ctx, t, playerX) {
    if (this.def.behavior === 'charger' && this.state === 'aim') {
      ctx.strokeStyle = 'rgba(255, 80, 60, 0.35)';
      ctx.lineWidth = this.r * 1.4;
      ctx.lineCap = 'round';
      ctx.beginPath();
      ctx.moveTo(this.x, this.y);
      ctx.lineTo(this.x + Math.cos(this.chargeA) * 260, this.y + Math.sin(this.chargeA) * 260);
      ctx.stroke();
    }
    Sprites.enemy(ctx, this, t, playerX);
  }
}

// Chefes: ciclo de ataques (perseguir, anel de projéteis, investida, invocação, espiral)
class Boss extends Enemy {
  constructor(def, x, y) {
    super(def, x, y, 1, false);
    this.boss = true;
    this.maxHp = def.hp;
    this.hp = def.hp;
    this.damage = def.damage;
    this.speed = def.speed;
    this.r = def.radius;
    this.xp = def.xp;
    this.kbResist = 0.97;
    this.state = 'chase';
    this.stateT = 2.5;
    this.lastAttack = null;
    this.rage = false;
  }

  nextAttack() {
    const options = this.def.attacks.filter(a => a !== this.lastAttack);
    const a = pick(options);
    this.lastAttack = a;
    this.state = a;
    switch (a) {
      case 'ring': this.shots = this.rage ? 5 : 3; this.shotT = 0.3; break;
      case 'charge': this.charges = this.rage ? 3 : 2; this.state = 'aim'; this.stateT = 0.8; break;
      case 'summon': this.stateT = 1; break;
      case 'spiral': this.stateT = 3.2; this.shotT = 0; this.spiralA = 0; break;
    }
  }

  toChase() {
    this.state = 'chase';
    this.stateT = this.rage ? rand(1.2, 2) : rand(2, 3.2);
  }

  update(dt, game) {
    this.t += dt;
    this.flash = Math.max(0, this.flash - dt);
    if (!this.rage && this.hp < this.maxHp * 0.5) {
      this.rage = true;
      game.addText(this.x, this.y - this.r - 20, 'Fúria!', '#ff5d5d', 26);
      game.shake(8);
    }
    const p = game.player;
    const dx = p.x - this.x, dy = p.y - this.y;
    const d = Math.hypot(dx, dy) || 1;
    let mx = dx / d, my = dy / d;
    let sp = this.speed * (this.rage ? 1.25 : 1);

    switch (this.state) {
      case 'chase':
        this.stateT -= dt;
        if (this.stateT <= 0) this.nextAttack();
        break;
      case 'ring': {
        sp *= 0.3;
        this.shotT -= dt;
        if (this.shotT <= 0) {
          this.shotT = 0.45;
          const n = this.def.id === 'calamity' ? 22 : 16;
          const off = Math.random() * TAU;
          for (let i = 0; i < n; i++) game.enemyShoot(this.x, this.y, off + (i / n) * TAU, 200, this.damage * 0.6, '#ff5d73');
          this.shots--;
          if (this.shots <= 0) this.toChase();
        }
        break;
      }
      case 'aim':
        sp = 0;
        this.stateT -= dt;
        if (this.stateT > 0.25) this.chargeA = Math.atan2(dy, dx);
        if (this.stateT <= 0) { this.state = 'charge'; this.stateT = 0.75; }
        break;
      case 'charge':
        mx = Math.cos(this.chargeA);
        my = Math.sin(this.chargeA);
        sp = this.speed * 6.5;
        this.stateT -= dt;
        if (Math.random() < 0.7) game.particle(this.x, this.y + this.r * 0.6, rand(-60, 60), rand(-60, 0), 0.5, '#4a2a2a', 6);
        if (this.stateT <= 0) {
          this.charges--;
          if (this.charges > 0) { this.state = 'aim'; this.stateT = 0.55; }
          else this.toChase();
        }
        break;
      case 'summon':
        sp = 0;
        this.stateT -= dt;
        if (this.stateT <= 0) {
          const types = this.def.id === 'calamity' ? ['wraith', 'bomber', 'brute', 'cultist'] : ['bat', 'slime', 'cultist'];
          const groups = this.rage ? 5 : 3;
          for (let i = 0; i < groups; i++) {
            const a = rand(0, TAU);
            game.queueGroup(3, false, pick(types), { x: this.x + Math.cos(a) * 160, y: this.y + Math.sin(a) * 160 });
          }
          game.addEffect(new RingEffect(this.x, this.y, 180, '#b23a48', 0.5, 6));
          this.toChase();
        }
        break;
      case 'spiral': {
        sp = 0;
        this.stateT -= dt;
        this.shotT -= dt;
        if (this.shotT <= 0) {
          this.shotT = 0.09;
          this.spiralA += 0.33;
          for (let k = 0; k < 3; k++) game.enemyShoot(this.x, this.y, this.spiralA + (k * TAU) / 3, 230, this.damage * 0.55, '#ff9f1a');
        }
        if (this.stateT <= 0) this.toChase();
        break;
      }
    }

    this.x += mx * sp * dt;
    this.y += my * sp * dt;
    this.x = clamp(this.x, this.r, ARENA.w - this.r);
    this.y = clamp(this.y, this.r, ARENA.h - this.r);
  }

  draw(ctx, t, playerX) {
    if (this.state === 'aim') {
      ctx.strokeStyle = 'rgba(255, 60, 40, 0.3)';
      ctx.lineWidth = this.r * 1.6;
      ctx.lineCap = 'round';
      ctx.beginPath();
      ctx.moveTo(this.x, this.y);
      ctx.lineTo(this.x + Math.cos(this.chargeA) * 520, this.y + Math.sin(this.chargeA) * 520);
      ctx.stroke();
    }
    Sprites.boss(ctx, this, t, playerX);
  }
}

class Projectile {
  constructor(o) {
    this.x = 0;
    this.y = 0;
    this.vx = 0;
    this.vy = 0;
    this.r = 6;
    this.damage = 10;
    this.pierce = 0;
    this.bounces = 0;
    this.explode = 0;
    this.homing = 0;
    this.gravity = 0;
    this.knockback = 120;
    this.life = 2;
    this.spin = 0;
    this.rot = 0;
    this.kind = 'orb';
    this.color = '#fff';
    this.target = null;
    Object.assign(this, o);
    this.hit = new Set();
    this.dead = false;
  }

  update(dt, game) {
    this.life -= dt;
    if (this.life <= 0) { this.dead = true; return; }

    if (this.homing) {
      if (!this.target || this.target.dead) this.target = game.nearestEnemy(this.x, this.y, 700, this.hit);
      if (this.target) {
        const sp = Math.hypot(this.vx, this.vy);
        const cur = Math.atan2(this.vy, this.vx);
        const want = angleTo(this.x, this.y, this.target.x, this.target.y);
        const diff = normAngle(want - cur);
        const a = cur + clamp(diff, -this.homing * dt, this.homing * dt);
        this.vx = Math.cos(a) * sp;
        this.vy = Math.sin(a) * sp;
      }
    }
    if (this.gravity) this.vy += this.gravity * dt;
    this.x += this.vx * dt;
    this.y += this.vy * dt;
    this.rot += this.spin * dt;

    if (this.kind === 'fireball' && Math.random() < 0.6) game.particle(this.x, this.y, rand(-20, 20), rand(-20, 20), 0.3, chance(0.5) ? '#ff7a2f' : '#ffd23f', 4);
    if (this.kind === 'skull' && Math.random() < 0.4) game.particle(this.x, this.y, rand(-15, 15), rand(-15, 15), 0.35, '#7dffb2', 3);

    const m = this.gravity ? 400 : 60;
    if (this.x < -m || this.x > ARENA.w + m || this.y < -m || this.y > ARENA.h + m) this.dead = true;
  }
}

class Pickup {
  constructor(kind, x, y, value = 1, gold = 0) {
    this.kind = kind;
    this.x = x;
    this.y = y;
    this.value = value;
    this.gold = gold;
    const a = rand(0, TAU), s = kind === 'chest' ? 0 : rand(30, 130);
    this.vx = Math.cos(a) * s;
    this.vy = Math.sin(a) * s;
    this.magnet = false;
    this.speed = 0;
    this.t = rand(0, 10);
    this.dead = false;
  }

  update(dt, game) {
    const p = game.player;
    const dx = p.x - this.x, dy = p.y - this.y;
    const d = Math.hypot(dx, dy) || 1;
    const range = this.kind === 'chest' ? 50 : p.stats.pickupRange;
    if (!this.magnet && d < range) this.magnet = true;
    if (this.magnet) {
      this.speed = Math.max(this.speed, 180) + 1500 * dt;
      const step = Math.min(this.speed * dt, d);
      this.x += (dx / d) * step;
      this.y += (dy / d) * step;
    } else {
      this.x += this.vx * dt;
      this.y += this.vy * dt;
      const decay = Math.exp(-dt * 6);
      this.vx *= decay;
      this.vy *= decay;
    }
    if (d < p.r + 8) {
      this.dead = true;
      game.collect(this);
    }
  }
}

// Esqueletos invocados pelo Necromante
class Minion {
  constructor(x, y, damage, life) {
    this.x = x;
    this.y = y;
    this.r = 10;
    this.damage = damage;
    this.life = life;
    this.speed = 235;
    this.attackT = 0;
    this.retarget = 0;
    this.target = null;
    this.seed = Math.random() * 10;
    this.dead = false;
  }

  update(dt, game) {
    this.life -= dt;
    if (this.life <= 0) {
      this.dead = true;
      game.burst(this.x, this.y, '#e9e4d8', 6);
      return;
    }
    this.attackT -= dt;
    this.retarget -= dt;
    if (!this.target || this.target.dead || this.retarget <= 0) {
      this.target = game.nearestEnemy(this.x, this.y, 600);
      this.retarget = 0.5;
    }
    let tx, ty;
    if (this.target) { tx = this.target.x; ty = this.target.y; }
    else {
      const p = game.player;
      const a = game.time * 2 + this.seed;
      tx = p.x + Math.cos(a) * 60;
      ty = p.y + Math.sin(a) * 60;
    }
    const dx = tx - this.x, dy = ty - this.y;
    const d = Math.hypot(dx, dy) || 1;
    const reach = this.target ? this.target.r + this.r + 2 : 4;
    if (d > reach) {
      const step = Math.min(this.speed * dt, d - reach);
      this.x += (dx / d) * step;
      this.y += (dy / d) * step;
    } else if (this.target && this.attackT <= 0) {
      this.attackT = 0.55;
      game.hitEnemy(this.target, this.damage, { knockback: 90, angle: Math.atan2(dy, dx) });
      game.particle(this.target.x, this.target.y, rand(-40, 40), rand(-40, 40), 0.25, '#e9e4d8', 4);
    }
  }
}

// ---------- Efeitos visuais ----------

class FloatText {
  constructor(x, y, text, color, size) {
    this.x = x + rand(-8, 8);
    this.y = y;
    this.text = String(text);
    this.color = color;
    this.size = size;
    this.life = 0.75;
    this.vy = -70;
  }

  update(dt) {
    this.life -= dt;
    this.y += this.vy * dt;
    this.vy *= Math.exp(-dt * 3);
    return this.life > 0;
  }

  // A fonte é definida pelo Game antes de desenhar (evita trocar a cada texto)
  draw(ctx) {
    ctx.globalAlpha = clamp(this.life / 0.3, 0, 1);
    ctx.fillStyle = 'rgba(10, 6, 12, 0.9)';
    ctx.fillText(this.text, this.x + 1.5, this.y + 1.5);
    ctx.fillStyle = this.color;
    ctx.fillText(this.text, this.x, this.y);
    ctx.globalAlpha = 1;
  }
}

class RingEffect {
  constructor(x, y, radius, color, duration = 0.4, width = 4) {
    Object.assign(this, { x, y, radius, color, duration, width, t: 0 });
  }

  update(dt) { this.t += dt; return this.t < this.duration; }

  draw(ctx) {
    const k = this.t / this.duration;
    ctx.globalAlpha = 1 - k;
    ctx.strokeStyle = this.color;
    ctx.lineWidth = this.width * (1 - k) + 1;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius * (0.3 + 0.7 * Math.sqrt(k)), 0, TAU);
    ctx.stroke();
    ctx.globalAlpha = 1;
  }
}

class ExplosionEffect {
  constructor(x, y, radius, color) {
    Object.assign(this, { x, y, radius, color, t: 0, duration: 0.35 });
  }

  update(dt) { this.t += dt; return this.t < this.duration; }

  draw(ctx) {
    const k = this.t / this.duration;
    ctx.globalAlpha = (1 - k) * 0.55;
    ctx.fillStyle = this.color;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius * (0.5 + 0.5 * k), 0, TAU);
    ctx.fill();
    ctx.globalAlpha = (1 - k) * 0.9;
    ctx.fillStyle = '#fff3c4';
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius * 0.45 * (1 - k), 0, TAU);
    ctx.fill();
    ctx.globalAlpha = 1;
  }
}

class SlashEffect {
  constructor(follow, angle, radius, arc, color) {
    Object.assign(this, { follow, angle, radius, arc, color, t: 0, duration: 0.18 });
  }

  update(dt) { this.t += dt; return this.t < this.duration; }

  draw(ctx) {
    const k = this.t / this.duration;
    const { x, y } = this.follow;
    const a0 = this.angle - this.arc / 2;
    const sweep = this.arc * Math.min(1, k * 2.2);
    ctx.globalAlpha = 1 - k * 0.8;
    ctx.fillStyle = this.color;
    ctx.beginPath();
    ctx.arc(x, y, this.radius, a0, a0 + sweep);
    ctx.arc(x, y, this.radius * 0.55, a0 + sweep, a0, true);
    ctx.closePath();
    ctx.globalAlpha *= 0.45;
    ctx.fill();
    ctx.globalAlpha = 1 - k * 0.8;
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(x, y, this.radius, a0, a0 + sweep);
    ctx.stroke();
    ctx.globalAlpha = 1;
  }
}

class LightningEffect {
  constructor(points, color, duration = 0.2, width = 3) {
    this.color = color;
    this.duration = duration;
    this.width = width;
    this.t = 0;
    // pré-calcula o zigue-zague
    this.path = [];
    for (let i = 0; i < points.length - 1; i++) {
      const a = points[i], b = points[i + 1];
      const segs = Math.max(2, Math.floor(dist(a.x, a.y, b.x, b.y) / 22));
      for (let s = 0; s < segs; s++) {
        const k = s / segs;
        const j = s === 0 ? 0 : 12;
        this.path.push({ x: lerp(a.x, b.x, k) + rand(-j, j), y: lerp(a.y, b.y, k) + rand(-j, j) });
      }
    }
    const last = points[points.length - 1];
    this.path.push({ x: last.x, y: last.y });
  }

  update(dt) { this.t += dt; return this.t < this.duration; }

  draw(ctx) {
    const k = this.t / this.duration;
    const stroke = (style, w) => {
      ctx.strokeStyle = style;
      ctx.lineWidth = w;
      ctx.lineJoin = 'round';
      ctx.beginPath();
      this.path.forEach((p, i) => (i ? ctx.lineTo(p.x, p.y) : ctx.moveTo(p.x, p.y)));
      ctx.stroke();
    };
    ctx.globalAlpha = (1 - k) * 0.4;
    stroke(this.color, this.width * 3);
    ctx.globalAlpha = 1 - k;
    stroke('#ffffff', this.width);
    ctx.globalAlpha = 1;
  }
}

class MeteorEffect {
  constructor(x, y, radius, fall, onImpact) {
    Object.assign(this, { x, y, radius, fall, onImpact, t: 0, done: false });
  }

  update(dt) {
    this.t += dt;
    if (!this.done && this.t >= this.fall) {
      this.done = true;
      this.onImpact();
      return false;
    }
    return true;
  }

  draw(ctx) {
    const k = clamp(this.t / this.fall, 0, 1);
    ctx.strokeStyle = 'rgba(255, 106, 61, 0.7)';
    ctx.fillStyle = 'rgba(255, 106, 61, 0.12)';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius * (0.4 + 0.6 * k), 0, TAU);
    ctx.fill();
    ctx.stroke();
    const mx = this.x + (1 - k) * 160, my = this.y - (1 - k) * 520;
    ctx.fillStyle = 'rgba(255, 160, 60, 0.35)';
    ctx.beginPath();
    ctx.arc(mx, my, 22, 0, TAU);
    ctx.fill();
    ctx.fillStyle = '#ff7a2f';
    ctx.beginPath();
    ctx.arc(mx, my, 13, 0, TAU);
    ctx.fill();
    ctx.fillStyle = '#ffe08a';
    ctx.beginPath();
    ctx.arc(mx - 3, my + 3, 6, 0, TAU);
    ctx.fill();
  }
}

class AfterimageEffect {
  constructor(x, y, player, duration) {
    Object.assign(this, { x, y, hero: player.hero, facing: player.facing, duration, t: 0 });
  }

  update(dt) { this.t += dt; return this.t < this.duration; }

  draw(ctx) {
    ctx.globalAlpha = (1 - this.t / this.duration) * 0.45;
    Sprites.hero(ctx, this.hero, this.x, this.y, 17, this.facing, 0, {});
    ctx.globalAlpha = 1;
  }
}

class SlashLineEffect {
  constructor(x1, y1, x2, y2, color) {
    Object.assign(this, { x1, y1, x2, y2, color, t: 0, duration: 0.3 });
  }

  update(dt) { this.t += dt; return this.t < this.duration; }

  draw(ctx) {
    const k = this.t / this.duration;
    ctx.globalAlpha = 1 - k;
    ctx.lineCap = 'round';
    ctx.strokeStyle = this.color;
    ctx.lineWidth = 14 * (1 - k) + 2;
    ctx.beginPath();
    ctx.moveTo(this.x1, this.y1);
    ctx.lineTo(this.x2, this.y2);
    ctx.stroke();
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 3 * (1 - k) + 1;
    ctx.stroke();
    ctx.globalAlpha = 1;
  }
}

class PillarEffect {
  constructor(follow, radius) {
    Object.assign(this, { follow, radius, t: 0, duration: 0.8 });
  }

  update(dt) { this.t += dt; return this.t < this.duration; }

  draw(ctx) {
    const k = this.t / this.duration;
    const { x, y } = this.follow;
    ctx.globalAlpha = (1 - k) * 0.35;
    ctx.fillStyle = '#ffe08a';
    ctx.beginPath();
    ctx.arc(x, y, this.radius * Math.min(1, k * 3), 0, TAU);
    ctx.fill();
    ctx.globalAlpha = (1 - k) * 0.8;
    ctx.fillStyle = '#fff6d6';
    const w = 50 * (1 - k) + 10;
    ctx.fillRect(x - w / 2, y - 900, w, 900);
    ctx.globalAlpha = 1;
  }
}
