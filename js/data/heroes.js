'use strict';
// Heróis jogáveis. Cada um tem atributos próprios (mods), uma arma inicial
// e uma habilidade especial ativada com Espaço (ou o botão na tela).
//
// Para criar um novo herói: copie um bloco, mude o id, cores, mods,
// startWeapon (id de WEAPONS) e escreva o cast() da habilidade.
// Para o visual, adicione um "case" com o id em Sprites.hero (sprites.js).

const HEROES = [
  {
    id: 'knight',
    name: 'Cavaleiro',
    title: 'Escudo do Reino',
    color: '#5b8def',
    dark: '#23407d',
    desc: 'Linha de frente. Muita vida e armadura, mas é lento.',
    startWeapon: 'sword',
    mods: { maxHp: 30, armor: 4, speed: -0.08 },
    ability: {
      name: 'Escudo Divino',
      icon: '🛡️',
      cooldown: 14,
      desc: 'Fica invulnerável por 3s e solta uma onda de choque que arremessa os inimigos.',
      cast(game, p) {
        p.invuln = Math.max(p.invuln, 3);
        p.shield = 3;
        const R = 210 * p.stats.area;
        game.damageArea(p.x, p.y, R, 45 * game.abilityScale(), { knockback: 700 });
        game.addEffect(new RingEffect(p.x, p.y, R, '#cfe0ff', 0.45, 10));
        game.shake(8);
      },
    },
  },
  {
    id: 'mage',
    name: 'Maga',
    title: 'Senhora das Chamas',
    color: '#e8553a',
    dark: '#7a2416',
    desc: 'Dano em área devastador, porém frágil.',
    startWeapon: 'fireball',
    mods: { maxHp: -15, damage: 0.15, area: 0.15 },
    ability: {
      name: 'Chuva de Meteoros',
      icon: '☄️',
      cooldown: 16,
      desc: 'Invoca uma chuva de meteoros sobre os inimigos próximos.',
      cast(game, p) {
        const n = 9 + p.stats.projectiles * 2;
        for (let i = 0; i < n; i++) {
          game.schedule(i * 0.16, () => {
            const t = game.randomEnemy(p.x, p.y, 520);
            const x = t ? t.x + rand(-20, 20) : p.x + rand(-250, 250);
            const y = t ? t.y + rand(-20, 20) : p.y + rand(-250, 250);
            const r = 85 * p.stats.area;
            game.addEffect(new MeteorEffect(x, y, r, 0.5, () => {
              game.damageArea(x, y, r, 60 * game.abilityScale(), { knockback: 250 });
              game.explosion(x, y, r, '#ff7a2f');
              game.shake(4);
            }));
          });
        }
      },
    },
  },
  {
    id: 'ranger',
    name: 'Arqueira',
    title: 'Olho de Falcão',
    color: '#4caf6d',
    dark: '#1f5a35',
    desc: 'Ataques rápidos e críticos certeiros à distância.',
    startWeapon: 'bow',
    mods: { maxHp: -10, attackSpeed: 0.15, crit: 0.08 },
    ability: {
      name: 'Tempestade de Flechas',
      icon: '🎯',
      cooldown: 12,
      desc: 'Dispara três rajadas de flechas em todas as direções.',
      cast(game, p) {
        for (let v = 0; v < 3; v++) {
          game.schedule(v * 0.22, () => {
            const n = 22 + p.stats.projectiles * 4;
            for (let i = 0; i < n; i++) {
              const a = v * 0.15 + (i * TAU) / n;
              game.addProjectile({ kind: 'arrow', golden: true, x: p.x, y: p.y, vx: Math.cos(a) * 800, vy: Math.sin(a) * 800, r: 5, damage: 22 * game.abilityScale(), pierce: 3, life: 0.9, color: '#ffd76a' });
            }
            Sfx.play('shoot');
          });
        }
      },
    },
  },
  {
    id: 'ninja',
    name: 'Ninja',
    title: 'Lâmina Silenciosa',
    color: '#3a3a52',
    dark: '#15151f',
    desc: 'Rápido e esquivo. Habilidade com recarga curta.',
    startWeapon: 'shuriken',
    mods: { maxHp: -20, speed: 0.18, dodge: 0.1 },
    ability: {
      name: 'Passo Sombrio',
      icon: '💨',
      cooldown: 6,
      desc: 'Avança como um raio na direção do movimento, cortando tudo no caminho.',
      cast(game, p) {
        const sx = p.x, sy = p.y;
        const ex = clamp(sx + p.dirX * 270, p.r, ARENA.w - p.r);
        const ey = clamp(sy + p.dirY * 270, p.r, ARENA.h - p.r);
        for (let i = 0; i < 6; i++) {
          const k = i / 5;
          game.addEffect(new AfterimageEffect(lerp(sx, ex, k), lerp(sy, ey, k), p, 0.25 + k * 0.2));
        }
        p.x = ex;
        p.y = ey;
        p.invuln = Math.max(p.invuln, 0.5);
        const dmg = 55 * game.abilityScale();
        for (const e of game.enemies) {
          if (!e.dead && distToSegment(e.x, e.y, sx, sy, ex, ey) < e.r + 40) game.hitEnemy(e, dmg, { knockback: 220 });
        }
        game.addEffect(new SlashLineEffect(sx, sy, ex, ey, '#e04646'));
      },
    },
  },
  {
    id: 'necro',
    name: 'Necromante',
    title: 'Mestre das Almas',
    color: '#5b4387',
    dark: '#271a40',
    desc: 'Comanda os mortos e se cura com a vida dos inimigos.',
    startWeapon: 'skull',
    mods: { lifesteal: 0.03, xpGain: 0.15, speed: -0.04 },
    ability: {
      name: 'Exército dos Mortos',
      icon: '☠️',
      cooldown: 18,
      desc: 'Ergue esqueletos que lutam ao seu lado por 12 segundos.',
      cast(game, p) {
        const n = 5 + p.stats.projectiles;
        for (let i = 0; i < n; i++) {
          const a = (i * TAU) / n;
          const x = p.x + Math.cos(a) * 50, y = p.y + Math.sin(a) * 50;
          game.addMinion(new Minion(x, y, 16 * game.abilityScale(), 12));
          game.burst(x, y, '#7dffb2', 8);
        }
        game.addEffect(new RingEffect(p.x, p.y, 120, '#7dffb2', 0.5, 6));
      },
    },
  },
  {
    id: 'storm',
    name: 'Xamã',
    title: 'Voz do Trovão',
    color: '#2aa7c4',
    dark: '#0f4f61',
    desc: 'Controla o céu. Coleta de longe e recarrega rápido.',
    startWeapon: 'lightning',
    mods: { pickupRange: 40, cooldown: -0.15, speed: 0.05 },
    ability: {
      name: 'Fúria da Tempestade',
      icon: '🌩️',
      cooldown: 15,
      desc: 'Raios caem sem parar sobre os inimigos por 3,5 segundos.',
      cast(game, p) {
        for (let i = 0; i < 24; i++) {
          game.schedule(i * 0.15, () => {
            const t = game.randomEnemy(p.x, p.y, 520);
            if (!t) return;
            const r = 55 * p.stats.area;
            game.damageArea(t.x, t.y, r, 32 * game.abilityScale(), { knockback: 80 });
            game.addEffect(new LightningEffect([{ x: t.x + rand(-40, 40), y: t.y - 420 }, { x: t.x, y: t.y }], '#fff27a', 0.25, 4));
            game.addEffect(new RingEffect(t.x, t.y, r, '#fff27a', 0.25, 3));
            Sfx.play('zap');
          });
        }
      },
    },
  },
  {
    id: 'berserker',
    name: 'Bárbaro',
    title: 'Fúria das Montanhas',
    color: '#b5523b',
    dark: '#5a2015',
    desc: 'Força bruta. Fica imparável quando entra em fúria.',
    startWeapon: 'axe',
    mods: { maxHp: 20, damage: 0.1, armor: -2 },
    ability: {
      name: 'Fúria Sangrenta',
      icon: '🩸',
      cooldown: 15,
      desc: 'Por 6s: +60% vel. de ataque, +25% velocidade, +12% roubo de vida e +3 armadura.',
      cast(game, p) {
        p.addBuff('rage', { attackSpeed: 0.6, speed: 0.25, lifesteal: 0.12, armor: 3 }, 6);
        game.addEffect(new RingEffect(p.x, p.y, 140, '#ff4d4d', 0.4, 8));
        game.shake(5);
      },
    },
  },
  {
    id: 'paladin',
    name: 'Paladina',
    title: 'Luz Sagrada',
    color: '#efe2bf',
    dark: '#8f7440',
    desc: 'Resistente e regenera vida. Queima quem se aproxima.',
    startWeapon: 'aura',
    mods: { regen: 1.5, maxHp: 10, area: 0.1 },
    ability: {
      name: 'Julgamento Celestial',
      icon: '🌟',
      cooldown: 20,
      desc: 'Cura 30% da vida e faz descer um pilar de luz que fere todos ao redor.',
      cast(game, p) {
        p.heal(p.stats.maxHp * 0.3);
        const R = 300 * p.stats.area;
        game.addEffect(new PillarEffect(p, R));
        game.schedule(0.25, () => {
          game.damageArea(p.x, p.y, R, 50 * game.abilityScale(), { knockback: 350 });
          game.addEffect(new RingEffect(p.x, p.y, R, '#ffe08a', 0.5, 8));
          game.shake(6);
        });
      },
    },
  },
];
