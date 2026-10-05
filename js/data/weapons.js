'use strict';
// Armas automáticas. Cada arma ataca sozinha quando sua recarga termina.
//   stats(nível)  -> números da arma naquele nível (1 a maxLevel)
//   fire(...)     -> ataca; retorna true se atacou (false = sem alvo, tenta de novo logo)
//   update(...)   -> lógica contínua (opcional, ex.: lâminas orbitais)
//   draw(...)     -> desenho próprio (opcional)

// Rótulos usados para descrever melhorias de nível automaticamente
const WEAPON_STAT_LABELS = {
  damage: 'Dano',
  cooldown: 'Recarga',
  count: 'Quantidade',
  pierce: 'Perfuração',
  bounces: 'Ricochetes',
  chains: 'Saltos',
  radius: 'Raio',
  arc: 'Ângulo',
};

const WEAPONS = {
  sword: {
    id: 'sword',
    name: 'Espada Larga',
    icon: '🗡️',
    color: '#dfe7f2',
    maxLevel: 5,
    desc: 'Golpe em arco que acerta todos à frente e empurra.',
    stats: lv => ({ damage: 14 + 7 * lv, cooldown: 1.05 - 0.07 * lv, range: 115, arc: 1.7 + 0.15 * lv, knockback: 280 }),
    fire(game, p, w, s) {
      const range = s.range * p.stats.area;
      const target = game.nearestEnemy(p.x, p.y, range + 40);
      if (!target) return false;
      const base = angleTo(p.x, p.y, target.x, target.y);
      const n = 1 + p.stats.projectiles;
      for (let i = 0; i < n; i++) {
        const a = base + (i * TAU) / n;
        game.coneDamage(p.x, p.y, range, a, s.arc, s.damage, { knockback: s.knockback });
        game.addEffect(new SlashEffect(p, a, range, s.arc, this.color));
      }
      Sfx.play('swing');
      return true;
    },
  },

  fireball: {
    id: 'fireball',
    name: 'Bola de Fogo',
    icon: '🔥',
    color: '#ff7a2f',
    maxLevel: 5,
    desc: 'Projétil que explode em área ao atingir.',
    stats: lv => ({ damage: 16 + 8 * lv, cooldown: 1.4 - 0.1 * lv, speed: 400, radius: 42 + 6 * lv, count: lv >= 4 ? 2 : 1, range: 520 }),
    fire(game, p, w, s) {
      const t = game.nearestEnemy(p.x, p.y, s.range);
      if (!t) return false;
      const base = angleTo(p.x, p.y, t.x, t.y);
      const n = s.count + p.stats.projectiles;
      for (let i = 0; i < n; i++) {
        const a = base + (i - (n - 1) / 2) * 0.18;
        game.addProjectile({ kind: 'fireball', x: p.x, y: p.y, vx: Math.cos(a) * s.speed, vy: Math.sin(a) * s.speed, r: 9, damage: s.damage, explode: s.radius * p.stats.area, life: 1.6, color: this.color });
      }
      Sfx.play('shoot');
      return true;
    },
  },

  bow: {
    id: 'bow',
    name: 'Arco Longo',
    icon: '🏹',
    color: '#e8dcc0',
    maxLevel: 5,
    desc: 'Flechas rápidas que atravessam inimigos.',
    stats: lv => ({ damage: 10 + 5 * lv, cooldown: 0.7 - 0.04 * lv, speed: 720, pierce: 1 + Math.floor(lv / 2), count: 1 + (lv >= 3 ? 1 : 0) + (lv >= 5 ? 1 : 0), range: 620 }),
    fire(game, p, w, s) {
      const t = game.nearestEnemy(p.x, p.y, s.range);
      if (!t) return false;
      const base = angleTo(p.x, p.y, t.x, t.y);
      const n = s.count + p.stats.projectiles;
      for (let i = 0; i < n; i++) {
        const a = base + (i - (n - 1) / 2) * 0.1;
        game.addProjectile({ kind: 'arrow', x: p.x, y: p.y, vx: Math.cos(a) * s.speed, vy: Math.sin(a) * s.speed, r: 5, damage: s.damage, pierce: s.pierce, life: 1.2, color: this.color });
      }
      Sfx.play('shoot');
      return true;
    },
  },

  shuriken: {
    id: 'shuriken',
    name: 'Shuriken',
    icon: '✴️',
    color: '#d7dde8',
    maxLevel: 5,
    desc: 'Estrelas que ricocheteiam de inimigo em inimigo.',
    stats: lv => ({ damage: 8 + 4 * lv, cooldown: 0.95 - 0.05 * lv, speed: 540, bounces: 1 + Math.floor(lv / 2), count: 2 + (lv >= 4 ? 1 : 0), range: 460 }),
    fire(game, p, w, s) {
      const t = game.nearestEnemy(p.x, p.y, s.range);
      if (!t) return false;
      const base = angleTo(p.x, p.y, t.x, t.y);
      const n = s.count + p.stats.projectiles;
      for (let i = 0; i < n; i++) {
        const a = base + (i - (n - 1) / 2) * 0.3;
        game.addProjectile({ kind: 'shuriken', x: p.x, y: p.y, vx: Math.cos(a) * s.speed, vy: Math.sin(a) * s.speed, r: 7, damage: s.damage, bounces: s.bounces, life: 1.5, spin: 18, color: this.color });
      }
      Sfx.play('shoot');
      return true;
    },
  },

  skull: {
    id: 'skull',
    name: 'Caveira Teleguiada',
    icon: '💀',
    color: '#7dffb2',
    maxLevel: 5,
    desc: 'Caveiras que perseguem o inimigo mais próximo.',
    stats: lv => ({ damage: 14 + 6 * lv, cooldown: 1.25 - 0.06 * lv, speed: 310, count: 1 + Math.floor((lv - 1) / 2), range: 650 }),
    fire(game, p, w, s) {
      const t = game.nearestEnemy(p.x, p.y, s.range);
      if (!t) return false;
      const n = s.count + p.stats.projectiles;
      for (let i = 0; i < n; i++) {
        const a = rand(0, TAU);
        game.addProjectile({ kind: 'skull', x: p.x, y: p.y, vx: Math.cos(a) * s.speed, vy: Math.sin(a) * s.speed, r: 8, damage: s.damage, homing: 5.5, target: t, life: 3.5, color: this.color });
      }
      Sfx.play('shoot');
      return true;
    },
  },

  lightning: {
    id: 'lightning',
    name: 'Corrente de Raios',
    icon: '⚡',
    color: '#bff6ff',
    maxLevel: 5,
    desc: 'Raio instantâneo que salta entre inimigos próximos.',
    stats: lv => ({ damage: 12 + 6 * lv, cooldown: 1.3 - 0.07 * lv, chains: 2 + lv, range: 380, chainRange: 170 }),
    fire(game, p, w, s) {
      const first = game.nearestEnemy(p.x, p.y, s.range);
      if (!first) return false;
      const bolts = 1 + p.stats.projectiles;
      const used = new Set();
      for (let b = 0; b < bolts; b++) {
        let cur = b === 0 ? first : game.randomEnemy(p.x, p.y, s.range, used);
        if (!cur) break;
        const pts = [{ x: p.x, y: p.y - 10 }];
        for (let i = 0; i <= s.chains && cur; i++) {
          used.add(cur);
          pts.push({ x: cur.x, y: cur.y });
          game.hitEnemy(cur, s.damage, { knockback: 40 });
          cur = game.nearestEnemy(cur.x, cur.y, s.chainRange, used);
        }
        game.addEffect(new LightningEffect(pts, '#7fe9ff'));
      }
      Sfx.play('zap');
      return true;
    },
  },

  aura: {
    id: 'aura',
    name: 'Aura Sagrada',
    icon: '✨',
    color: '#ffe08a',
    maxLevel: 5,
    desc: 'Queima continuamente os inimigos ao seu redor.',
    stats: lv => ({ damage: 4 + 3 * lv, cooldown: 0.5, radius: 70 + 12 * lv }),
    fire(game, p, w, s) {
      game.damageArea(p.x, p.y, s.radius * p.stats.area, s.damage, { knockback: 30 });
      return true;
    },
    drawUnder(ctx, game, p, w, s) {
      const R = s.radius * p.stats.area;
      const t = game.time;
      ctx.fillStyle = 'rgba(255, 224, 138, 0.09)';
      ctx.beginPath();
      ctx.arc(p.x, p.y, R, 0, TAU);
      ctx.fill();
      ctx.strokeStyle = 'rgba(255, 224, 138, 0.45)';
      ctx.lineWidth = 2;
      ctx.setLineDash([10, 12]);
      ctx.lineDashOffset = -t * 40;
      ctx.beginPath();
      ctx.arc(p.x, p.y, R, 0, TAU);
      ctx.stroke();
      ctx.setLineDash([]);
    },
  },

  orbit: {
    id: 'orbit',
    name: 'Lâminas Orbitais',
    icon: '🌀',
    color: '#c7b8ff',
    maxLevel: 5,
    desc: 'Lâminas giram ao seu redor cortando quem encostar.',
    stats: lv => ({ damage: 8 + 4 * lv, count: [2, 3, 3, 4, 5][lv - 1], radius: 85, spin: 3.2 + 0.3 * lv }),
    update(game, p, w, s, dt) {
      w.data.angle = (w.data.angle || 0) + s.spin * dt;
      const n = s.count + p.stats.projectiles;
      const R = s.radius * p.stats.area;
      const blades = (w.data.blades = []);
      for (let i = 0; i < n; i++) {
        const a = w.data.angle + (i * TAU) / n;
        const bx = p.x + Math.cos(a) * R, by = p.y + Math.sin(a) * R;
        blades.push({ x: bx, y: by, a });
        game.grid.query(bx, by, 80, e => {
          if (e.dead || game.time - e.orbitHit < 0.35) return;
          if (dist2(bx, by, e.x, e.y) < (14 + e.r) ** 2) {
            e.orbitHit = game.time;
            game.hitEnemy(e, s.damage, { knockback: 160, angle: a + Math.PI / 2 });
          }
        });
      }
    },
    draw(ctx, game, p, w) {
      for (const b of w.data.blades || []) {
        ctx.save();
        ctx.translate(b.x, b.y);
        ctx.rotate(b.a + game.time * 10);
        ctx.fillStyle = 'rgba(199, 184, 255, 0.3)';
        ctx.beginPath();
        ctx.arc(0, 0, 16, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#e9e4ff';
        ctx.strokeStyle = '#6b5fb0';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        for (let i = 0; i < 3; i++) {
          const a = (i / 3) * TAU;
          ctx.moveTo(Math.cos(a) * 3, Math.sin(a) * 3);
          ctx.quadraticCurveTo(Math.cos(a + 0.6) * 14, Math.sin(a + 0.6) * 14, Math.cos(a + 1.1) * 13, Math.sin(a + 1.1) * 13);
        }
        ctx.fill();
        ctx.stroke();
        ctx.restore();
      }
    },
  },

  axe: {
    id: 'axe',
    name: 'Machado Arremessado',
    icon: '🪓',
    color: '#c9cfd8',
    maxLevel: 5,
    desc: 'Arremessado para o alto em arco; atravessa tudo.',
    stats: lv => ({ damage: 22 + 9 * lv, cooldown: 1.6 - 0.08 * lv, count: 1 + (lv >= 3 ? 1 : 0) + (lv >= 5 ? 1 : 0) }),
    fire(game, p, w, s) {
      if (!game.enemies.length) return false;
      const n = s.count + p.stats.projectiles;
      for (let i = 0; i < n; i++) {
        const vx = (i - (n - 1) / 2) * 150 + p.facing * 90 + rand(-40, 40);
        game.addProjectile({ kind: 'axe', x: p.x, y: p.y - 10, vx, vy: -rand(560, 660), gravity: 1250, r: 13, damage: s.damage, pierce: 999, life: 2.2, spin: 12 * p.facing, knockback: 140, color: this.color });
      }
      Sfx.play('swing');
      return true;
    },
  },
};

// Lista legível das mudanças de um nível para o próximo (ex.: "Dano 21 → 28")
function weaponLevelChanges(def, fromLevel) {
  const a = def.stats(fromLevel), b = def.stats(fromLevel + 1);
  const out = [];
  for (const k in WEAPON_STAT_LABELS) {
    if (!(k in a) || Math.abs(a[k] - b[k]) < 1e-6) continue;
    const show = v => (k === 'cooldown' ? fmtNum(v, 2) + 's' : k === 'arc' ? Math.round((v * 180) / Math.PI) + '°' : Math.round(v));
    out.push({ text: `${WEAPON_STAT_LABELS[k]} ${show(a[k])} → ${show(b[k])}`, good: true });
  }
  return out;
}
