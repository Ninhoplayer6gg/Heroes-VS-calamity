'use strict';
// Desenho de todos os personagens e objetos usando formas do Canvas (sem imagens)

const Sprites = {
  // Sombras de muitos inimigos num único preenchimento (bem mais rápido)
  shadows(ctx, list) {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.35)';
    ctx.beginPath();
    for (const e of list) {
      if (e.boss || e.def.behavior === 'phase') continue;
      ctx.moveTo(e.x + e.r * 0.95, e.y + e.r * 0.85);
      ctx.ellipse(e.x, e.y + e.r * 0.85, e.r * 0.95, e.r * 0.35, 0, 0, TAU);
    }
    ctx.fill();
  },

  shadow(ctx, x, y, r) {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.35)';
    ctx.beginPath();
    ctx.ellipse(x, y + r * 0.85, r * 0.95, r * 0.35, 0, 0, TAU);
    ctx.fill();
  },

  body(ctx, x, y, r, fill, stroke) {
    ctx.fillStyle = fill;
    ctx.strokeStyle = stroke;
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.arc(x, y, r, 0, TAU);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = 'rgba(255, 255, 255, 0.16)';
    ctx.beginPath();
    ctx.ellipse(x - r * 0.3, y - r * 0.38, r * 0.45, r * 0.28, -0.5, 0, TAU);
    ctx.fill();
  },

  eyes(ctx, x, y, r, facing, opts = {}) {
    const ex = x + facing * r * 0.22;
    const gap = r * 0.3;
    const er = opts.size || r * 0.19;
    for (const s of [-1, 1]) {
      const cx = ex + s * gap;
      if (opts.glow) {
        ctx.fillStyle = opts.glow;
        ctx.globalAlpha = 0.35;
        ctx.beginPath();
        ctx.arc(cx, y, er * 2.1, 0, TAU);
        ctx.fill();
        ctx.globalAlpha = 1;
        ctx.fillStyle = opts.glow;
        ctx.beginPath();
        ctx.arc(cx, y, er * 0.8, 0, TAU);
        ctx.fill();
        continue;
      }
      ctx.fillStyle = opts.white || '#fff';
      ctx.beginPath();
      ctx.ellipse(cx, y, er, er * 1.25, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = opts.pupil || '#1a1220';
      ctx.beginPath();
      ctx.arc(cx + facing * er * 0.35, y + er * 0.1, er * 0.55, 0, TAU);
      ctx.fill();
      if (opts.angry) {
        ctx.strokeStyle = opts.brow || '#1a1220';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(cx - er * 1.1, y - er * (s === 1 ? 1.9 : 1.2));
        ctx.lineTo(cx + er * 1.1, y - er * (s === 1 ? 1.2 : 1.9));
        ctx.stroke();
      }
    }
  },

  // ---------- Heróis ----------
  hero(ctx, hero, x, y, r, facing, t, opts = {}) {
    const bob = opts.moving ? Math.abs(Math.sin(t * 11)) * 3 : Math.sin(t * 2.2) * 1;
    this.shadow(ctx, x, y, r);
    const cy = y - bob;
    const f = facing >= 0 ? 1 : -1;
    const fill = opts.flash ? '#ffffff' : hero.color;

    // Detalhes que ficam atrás do corpo
    if (hero.id === 'ninja') {
      ctx.strokeStyle = '#e04646';
      ctx.lineWidth = 4;
      ctx.lineCap = 'round';
      for (let i = 0; i < 2; i++) {
        const wave = Math.sin(t * 9 + i) * 4;
        ctx.beginPath();
        ctx.moveTo(x - f * r * 0.7, cy - r * 0.55);
        ctx.quadraticCurveTo(x - f * r * 1.3, cy - r * 0.5 + wave, x - f * r * (1.8 + i * 0.2), cy - r * (0.2 - i * 0.35) + wave);
        ctx.stroke();
      }
    }
    if (hero.id === 'paladin') {
      ctx.fillStyle = '#c23b22';
      ctx.beginPath();
      ctx.moveTo(x - r * 0.8, cy - r * 0.2);
      ctx.lineTo(x + r * 0.8, cy - r * 0.2);
      ctx.lineTo(x + r * 0.95 - f * r * 0.3, cy + r * 1.15);
      ctx.lineTo(x - r * 0.95 - f * r * 0.3, cy + r * 1.15);
      ctx.closePath();
      ctx.fill();
    }

    this.body(ctx, x, cy, r, fill, hero.dark);

    switch (hero.id) {
      case 'knight': {
        ctx.fillStyle = '#c9d3e0';
        ctx.strokeStyle = '#5d6b80';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, cy, r + 1.5, Math.PI * 1.02, Math.PI * 1.98);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = '#e04848';
        ctx.beginPath();
        ctx.ellipse(x - f * r * 0.25, cy - r * 1.1, r * 0.6, r * 0.22, -f * 0.35, 0, TAU);
        ctx.fill();
        this.eyes(ctx, x, cy + r * 0.2, r, f);
        break;
      }
      case 'mage': {
        this.eyes(ctx, x, cy + r * 0.05, r, f);
        ctx.fillStyle = '#4b2a7a';
        ctx.strokeStyle = '#2a1546';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(x - r * 0.95, cy - r * 0.45);
        ctx.quadraticCurveTo(x - f * r * 0.2, cy - r * 1.4, x - f * r * 0.85, cy - r * 2.15);
        ctx.quadraticCurveTo(x + f * r * 0.1, cy - r * 1.3, x + r * 0.95, cy - r * 0.45);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.beginPath();
        ctx.ellipse(x, cy - r * 0.45, r * 1.2, r * 0.28, 0, 0, TAU);
        ctx.fill();
        ctx.stroke();
        ctx.strokeStyle = '#f2c14e';
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.moveTo(x - r * 0.8, cy - r * 0.7);
        ctx.quadraticCurveTo(x, cy - r * 0.85, x + r * 0.8, cy - r * 0.7);
        ctx.stroke();
        break;
      }
      case 'ranger': {
        ctx.fillStyle = '#2f6b45';
        ctx.strokeStyle = '#1d4a2e';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, cy, r + 2, Math.PI * 0.95, Math.PI * 2.05);
        ctx.lineTo(x - f * r * 1.5, cy - r * 0.2);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.strokeStyle = '#7a5230';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(x - r * 0.75, cy + r * 0.1);
        ctx.lineTo(x + r * 0.55, cy + r * 0.85);
        ctx.stroke();
        this.eyes(ctx, x, cy + r * 0.08, r, f);
        break;
      }
      case 'ninja': {
        ctx.fillStyle = '#f1c9a5';
        ctx.beginPath();
        ctx.roundRect(x - r * 0.75 + f * r * 0.15, cy - r * 0.3, r * 1.5, r * 0.5, r * 0.25);
        ctx.fill();
        ctx.fillStyle = '#e04646';
        ctx.fillRect(x - r * 0.95, cy - r * 0.68, r * 1.9, r * 0.24);
        this.eyes(ctx, x, cy - r * 0.05, r, f, { size: r * 0.14, angry: true });
        break;
      }
      case 'necro': {
        ctx.fillStyle = '#2a1d3d';
        ctx.strokeStyle = '#150e20';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, cy, r + 2, Math.PI * 0.85, Math.PI * 2.15);
        ctx.lineTo(x, cy - r * 1.7);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = '#100a18';
        ctx.beginPath();
        ctx.ellipse(x + f * r * 0.15, cy + r * 0.05, r * 0.7, r * 0.55, 0, 0, TAU);
        ctx.fill();
        this.eyes(ctx, x, cy, r, f, { glow: '#7dffb2', size: r * 0.16 });
        break;
      }
      case 'storm': {
        ctx.fillStyle = '#fff27a';
        ctx.strokeStyle = '#c9a800';
        ctx.lineWidth = 1.5;
        for (const s of [-1, 0, 1]) {
          const bx = x + s * r * 0.55;
          const h = s === 0 ? r * 1.1 : r * 0.75;
          ctx.beginPath();
          ctx.moveTo(bx - r * 0.18, cy - r * 0.75);
          ctx.lineTo(bx + r * 0.05, cy - r * 0.75 - h * 0.55);
          ctx.lineTo(bx - r * 0.08, cy - r * 0.75 - h * 0.5);
          ctx.lineTo(bx + r * 0.12, cy - r * 0.75 - h);
          ctx.lineTo(bx + r * 0.2, cy - r * 0.75);
          ctx.closePath();
          ctx.fill();
          ctx.stroke();
        }
        this.eyes(ctx, x, cy + r * 0.05, r, f, { glow: '#e8fdff', size: r * 0.17 });
        if (Math.sin(t * 13) > 0.85) {
          ctx.strokeStyle = '#fff27a';
          ctx.lineWidth = 2;
          const a = t * 7;
          ctx.beginPath();
          ctx.moveTo(x + Math.cos(a) * r * 1.1, cy + Math.sin(a) * r * 1.1);
          ctx.lineTo(x + Math.cos(a + 0.3) * r * 1.45, cy + Math.sin(a + 0.3) * r * 1.2);
          ctx.stroke();
        }
        break;
      }
      case 'berserker': {
        ctx.fillStyle = '#d9822b';
        ctx.beginPath();
        ctx.arc(x + f * r * 0.15, cy + r * 0.35, r * 0.62, 0.1, Math.PI - 0.1);
        ctx.fill();
        ctx.fillStyle = '#7b7f8a';
        ctx.strokeStyle = '#43464f';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, cy, r + 1.5, Math.PI * 1.05, Math.PI * 1.95);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = '#efe6dc';
        for (const s of [-1, 1]) {
          ctx.beginPath();
          ctx.moveTo(x + s * r * 0.7, cy - r * 0.55);
          ctx.quadraticCurveTo(x + s * r * 1.5, cy - r * 0.8, x + s * r * 1.35, cy - r * 1.6);
          ctx.quadraticCurveTo(x + s * r * 1.1, cy - r * 0.95, x + s * r * 0.45, cy - r * 0.85);
          ctx.closePath();
          ctx.fill();
        }
        this.eyes(ctx, x, cy + r * 0.05, r, f, { angry: true });
        break;
      }
      case 'paladin': {
        ctx.strokeStyle = '#f2c14e';
        ctx.lineWidth = 3;
        ctx.globalAlpha = 0.75 + Math.sin(t * 3) * 0.2;
        ctx.beginPath();
        ctx.ellipse(x, cy - r * 1.35, r * 0.7, r * 0.22, 0, 0, TAU);
        ctx.stroke();
        ctx.globalAlpha = 1;
        ctx.fillStyle = '#f7d77a';
        ctx.beginPath();
        ctx.arc(x, cy, r + 1, Math.PI * 1.1, Math.PI * 1.9);
        ctx.closePath();
        ctx.fill();
        this.eyes(ctx, x, cy + r * 0.12, r, f);
        break;
      }
      default:
        this.eyes(ctx, x, cy, r, f);
    }
  },

  // ---------- Inimigos ----------
  enemy(ctx, e, t, playerX) {
    const f = playerX >= e.x ? 1 : -1;
    const r = e.r;
    const fill = e.flash > 0 ? '#ffffff' : e.color;
    const dark = e.def.dark || 'rgba(0,0,0,0.45)';
    const x = e.x, y = e.y;

    if (e.elite) {
      ctx.fillStyle = 'rgba(242, 193, 78, 0.18)';
      ctx.beginPath();
      ctx.arc(x, y, r * 1.45 + Math.sin(t * 6) * 2, 0, TAU);
      ctx.fill();
    }

    switch (e.def.id) {
      case 'slime': {
        const s = Math.sin(e.t * 6) * 0.1;
        ctx.fillStyle = fill;
        ctx.strokeStyle = dark;
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.ellipse(x, y + r * s * 0.5, r * (1 + s), r * (1 - s), 0, 0, TAU);
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = 'rgba(255,255,255,0.3)';
        ctx.beginPath();
        ctx.ellipse(x - r * 0.35, y - r * 0.4, r * 0.25, r * 0.15, -0.6, 0, TAU);
        ctx.fill();
        this.eyes(ctx, x, y, r, f, { angry: true, size: r * 0.17 });
        break;
      }
      case 'bat': {
        const flap = Math.sin(e.t * 22);
        ctx.fillStyle = e.flash > 0 ? '#fff' : '#5a2d7a';
        for (const s of [-1, 1]) {
          ctx.beginPath();
          ctx.moveTo(x + s * r * 0.5, y - r * 0.2);
          ctx.lineTo(x + s * r * 2.1, y - r * (0.9 + flap * 0.8));
          ctx.lineTo(x + s * r * 1.6, y + r * 0.2);
          ctx.lineTo(x + s * r * 1.1, y - r * 0.05);
          ctx.lineTo(x + s * r * 0.8, y + r * 0.5);
          ctx.closePath();
          ctx.fill();
        }
        this.body(ctx, x, y, r, fill, dark);
        this.eyes(ctx, x, y, r, f, { glow: '#ff4d4d', size: r * 0.16 });
        break;
      }
      case 'brute':
      case 'golem': {
        const golem = e.def.id === 'golem';
        ctx.fillStyle = fill;
        ctx.strokeStyle = dark;
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.roundRect(x - r, y - r * 0.9, r * 2, r * 1.85, r * (golem ? 0.3 : 0.55));
        ctx.fill();
        ctx.stroke();
        if (golem) {
          ctx.strokeStyle = '#ff8a3d';
          ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.moveTo(x - r * 0.6, y - r * 0.5);
          ctx.lineTo(x - r * 0.2, y);
          ctx.lineTo(x - r * 0.45, y + r * 0.6);
          ctx.moveTo(x + r * 0.5, y - r * 0.7);
          ctx.lineTo(x + r * 0.25, y - r * 0.1);
          ctx.stroke();
          this.eyes(ctx, x, y - r * 0.25, r, f, { glow: '#ff8a3d', size: r * 0.12 });
        } else {
          ctx.fillStyle = '#efe6dc';
          for (const s of [-1, 1]) {
            ctx.beginPath();
            ctx.moveTo(x + s * r * 0.55, y - r * 0.8);
            ctx.lineTo(x + s * r * 0.85, y - r * 1.45);
            ctx.lineTo(x + s * r * 0.25, y - r * 0.85);
            ctx.closePath();
            ctx.fill();
          }
          this.eyes(ctx, x, y - r * 0.2, r, f, { angry: true, size: r * 0.15 });
          ctx.fillStyle = '#2a1d1a';
          ctx.fillRect(x - r * 0.4 + f * r * 0.15, y + r * 0.3, r * 0.8, r * 0.18);
        }
        break;
      }
      case 'cultist': {
        ctx.fillStyle = fill;
        ctx.strokeStyle = dark;
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.moveTo(x, y - r * 1.5);
        ctx.quadraticCurveTo(x + r * 1.1, y - r * 0.2, x + r, y + r);
        ctx.lineTo(x - r, y + r);
        ctx.quadraticCurveTo(x - r * 1.1, y - r * 0.2, x, y - r * 1.5);
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = '#12080f';
        ctx.beginPath();
        ctx.ellipse(x + f * r * 0.15, y - r * 0.15, r * 0.5, r * 0.42, 0, 0, TAU);
        ctx.fill();
        const charge = e.shootT < 0.5 ? 1 : 0.6;
        ctx.fillStyle = '#ffd23f';
        ctx.globalAlpha = charge;
        ctx.beginPath();
        ctx.arc(x + f * r * 0.2, y - r * 0.15, r * 0.18, 0, TAU);
        ctx.fill();
        ctx.globalAlpha = 1;
        break;
      }
      case 'bomber': {
        const fuse = e.state === 'fuse';
        const swell = fuse ? 1 + (0.55 - e.stateT) * 0.5 : 1;
        const rr = r * swell;
        const blink = fuse && Math.sin(e.t * 40) > 0;
        this.body(ctx, x, y, rr, e.flash > 0 || blink ? '#ffffff' : '#3a3644', '#15131a');
        ctx.strokeStyle = '#a07a50';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(x + rr * 0.3, y - rr * 0.85);
        ctx.quadraticCurveTo(x + rr * 0.6, y - rr * 1.4, x + rr * 0.9, y - rr * 1.3);
        ctx.stroke();
        ctx.fillStyle = Math.sin(e.t * 30) > 0 ? '#ffd23f' : '#ff6a3d';
        ctx.beginPath();
        ctx.arc(x + rr * 0.9, y - rr * 1.3, 3.5 + Math.random() * 2, 0, TAU);
        ctx.fill();
        this.eyes(ctx, x, y, rr, f, { angry: true, size: rr * 0.17 });
        break;
      }
      case 'boar': {
        const shake = e.state === 'aim' ? Math.sin(e.t * 60) * 2 : 0;
        const bx = x + shake;
        ctx.fillStyle = fill;
        ctx.strokeStyle = dark;
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.ellipse(bx, y, r * 1.2, r * 0.95, 0, 0, TAU);
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = '#c48b6a';
        ctx.beginPath();
        ctx.ellipse(bx + f * r * 0.85, y + r * 0.15, r * 0.4, r * 0.32, 0, 0, TAU);
        ctx.fill();
        ctx.strokeStyle = '#efe6dc';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(bx + f * r * 0.7, y + r * 0.4);
        ctx.quadraticCurveTo(bx + f * r * 1.15, y + r * 0.35, bx + f * r * 1.2, y - r * 0.05);
        ctx.stroke();
        this.eyes(ctx, bx + f * r * 0.1, y - r * 0.35, r, f, { angry: true, size: r * 0.14 });
        break;
      }
      case 'wraith': {
        ctx.globalAlpha = 0.55 + Math.sin(e.t * 3) * 0.2;
        ctx.fillStyle = fill;
        ctx.beginPath();
        ctx.arc(x, y - r * 0.2, r, Math.PI, 0);
        const w = Math.sin(e.t * 8) * 3;
        ctx.lineTo(x + r, y + r * 0.8);
        for (let i = 0; i < 4; i++) {
          const px = x + r - (i + 1) * (r * 2) / 4;
          ctx.quadraticCurveTo(px + r * 0.25, y + r * (i % 2 ? 1.2 : 0.5) + w, px, y + r * 0.8);
        }
        ctx.closePath();
        ctx.fill();
        ctx.globalAlpha = 1;
        ctx.fillStyle = '#0d1a26';
        for (const s of [-1, 1]) {
          ctx.beginPath();
          ctx.ellipse(x + f * r * 0.2 + s * r * 0.32, y - r * 0.25, r * 0.16, r * 0.26, 0, 0, TAU);
          ctx.fill();
        }
        break;
      }
      default:
        this.body(ctx, x, y, r, fill, dark);
        this.eyes(ctx, x, y, r, f, { angry: true });
    }

    if (e.elite) {
      ctx.strokeStyle = '#f2c14e';
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.arc(x, y, r * 1.25, 0, TAU);
      ctx.stroke();
      this.crown(ctx, x, y - r * 1.55, r * 0.5);
      const w = r * 2;
      ctx.fillStyle = 'rgba(0,0,0,0.6)';
      ctx.fillRect(x - w / 2, y + r * 1.35, w, 4);
      ctx.fillStyle = '#f2c14e';
      ctx.fillRect(x - w / 2, y + r * 1.35, w * clamp(e.hp / e.maxHp, 0, 1), 4);
    }
  },

  crown(ctx, x, y, s) {
    ctx.fillStyle = '#f2c14e';
    ctx.beginPath();
    ctx.moveTo(x - s, y + s * 0.5);
    ctx.lineTo(x - s, y - s * 0.3);
    ctx.lineTo(x - s * 0.5, y + s * 0.1);
    ctx.lineTo(x, y - s * 0.6);
    ctx.lineTo(x + s * 0.5, y + s * 0.1);
    ctx.lineTo(x + s, y - s * 0.3);
    ctx.lineTo(x + s, y + s * 0.5);
    ctx.closePath();
    ctx.fill();
  },

  boss(ctx, b, t, playerX) {
    const r = b.r;
    const x = b.x, y = b.y;
    const f = playerX >= x ? 1 : -1;
    const fill = b.flash > 0 ? '#ffffff' : b.color;
    const final = b.def.id === 'calamity';

    this.shadow(ctx, x, y, r);

    // aura pulsante
    ctx.fillStyle = final ? 'rgba(255, 80, 40, 0.16)' : 'rgba(178, 58, 72, 0.16)';
    ctx.beginPath();
    ctx.arc(x, y, r * (1.4 + Math.sin(t * 4) * 0.08), 0, TAU);
    ctx.fill();

    // espinhos / coroa de chifres
    const spikes = final ? 12 : 7;
    ctx.fillStyle = final ? '#2a0f12' : '#3a1420';
    for (let i = 0; i < spikes; i++) {
      const a = final ? (i / spikes) * TAU + t * 0.5 : Math.PI + (i / (spikes - 1)) * Math.PI;
      const len = r * (final ? 1.5 : 1.45) + Math.sin(t * 5 + i) * 3;
      ctx.beginPath();
      ctx.moveTo(x + Math.cos(a - 0.18) * r * 0.9, y + Math.sin(a - 0.18) * r * 0.9);
      ctx.lineTo(x + Math.cos(a) * len, y + Math.sin(a) * len);
      ctx.lineTo(x + Math.cos(a + 0.18) * r * 0.9, y + Math.sin(a + 0.18) * r * 0.9);
      ctx.closePath();
      ctx.fill();
    }

    this.body(ctx, x, y, r, fill, '#1a0a0e');

    // olho central
    const charging = b.state === 'aim';
    ctx.fillStyle = '#12060a';
    ctx.beginPath();
    ctx.ellipse(x + f * r * 0.1, y - r * 0.05, r * 0.5, r * 0.36, 0, 0, TAU);
    ctx.fill();
    ctx.fillStyle = charging ? '#ffffff' : '#ffd23f';
    ctx.beginPath();
    ctx.ellipse(x + f * r * 0.22, y - r * 0.05, r * 0.2, r * 0.3, 0, 0, TAU);
    ctx.fill();
    ctx.fillStyle = '#12060a';
    ctx.beginPath();
    ctx.ellipse(x + f * r * 0.26, y - r * 0.05, r * 0.06, r * 0.24, 0, 0, TAU);
    ctx.fill();

    if (final) {
      for (const s of [-1, 1]) {
        ctx.fillStyle = '#ffd23f';
        ctx.beginPath();
        ctx.arc(x + s * r * 0.55, y - r * 0.5, r * 0.1, 0, TAU);
        ctx.arc(x + s * r * 0.6, y + r * 0.4, r * 0.08, 0, TAU);
        ctx.fill();
      }
    }
    if (b.rage) {
      ctx.strokeStyle = 'rgba(255, 60, 40, 0.6)';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(x, y, r * 1.12 + Math.sin(t * 20) * 2, 0, TAU);
      ctx.stroke();
    }
  },

  // ---------- Lacaio esqueleto (Necromante) ----------
  skeleton(ctx, m, t) {
    const x = m.x, y = m.y - Math.abs(Math.sin(t * 12 + m.seed)) * 2;
    const r = m.r;
    this.shadow(ctx, m.x, m.y, r);
    ctx.globalAlpha = m.life < 1 ? m.life : 1;
    ctx.fillStyle = '#e9e4d8';
    ctx.strokeStyle = '#6b6457';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(x, y - r * 0.2, r, 0, TAU);
    ctx.fill();
    ctx.stroke();
    ctx.fillRect(x - r * 0.5, y + r * 0.5, r, r * 0.45);
    ctx.fillStyle = '#1a1220';
    for (const s of [-1, 1]) {
      ctx.beginPath();
      ctx.arc(x + s * r * 0.38, y - r * 0.25, r * 0.24, 0, TAU);
      ctx.fill();
    }
    ctx.fillStyle = '#7dffb2';
    for (const s of [-1, 1]) {
      ctx.beginPath();
      ctx.arc(x + s * r * 0.38, y - r * 0.25, r * 0.1, 0, TAU);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  },

  // ---------- Projéteis ----------
  projectile(ctx, p) {
    const a = Math.atan2(p.vy, p.vx);
    switch (p.kind) {
      case 'arrow': {
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(a);
        ctx.strokeStyle = p.color;
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.moveTo(-16, 0);
        ctx.lineTo(8, 0);
        ctx.stroke();
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.moveTo(13, 0);
        ctx.lineTo(5, -4.5);
        ctx.lineTo(5, 4.5);
        ctx.closePath();
        ctx.fill();
        ctx.fillStyle = p.golden ? '#fff6c8' : '#4caf6d';
        ctx.fillRect(-17, -3.5, 5, 7);
        ctx.restore();
        break;
      }
      case 'fireball': {
        ctx.fillStyle = 'rgba(255, 122, 47, 0.3)';
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r * 2, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#ff7a2f';
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#ffe08a';
        ctx.beginPath();
        ctx.arc(p.x + Math.cos(a) * 2, p.y + Math.sin(a) * 2, p.r * 0.5, 0, TAU);
        ctx.fill();
        break;
      }
      case 'shuriken': {
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rot);
        ctx.fillStyle = '#d7dde8';
        ctx.strokeStyle = '#596274';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        for (let i = 0; i < 8; i++) {
          const rr = i % 2 === 0 ? p.r * 1.5 : p.r * 0.45;
          const aa = (i / 8) * TAU;
          ctx.lineTo(Math.cos(aa) * rr, Math.sin(aa) * rr);
        }
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = '#596274';
        ctx.beginPath();
        ctx.arc(0, 0, 2, 0, TAU);
        ctx.fill();
        ctx.restore();
        break;
      }
      case 'skull': {
        ctx.fillStyle = 'rgba(125, 255, 178, 0.25)';
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r * 1.8, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#e9e4d8';
        ctx.beginPath();
        ctx.arc(p.x, p.y - 1, p.r, 0, TAU);
        ctx.fill();
        ctx.fillRect(p.x - p.r * 0.5, p.y + p.r * 0.4, p.r, p.r * 0.5);
        ctx.fillStyle = '#163a2a';
        ctx.beginPath();
        ctx.arc(p.x - p.r * 0.38, p.y - 1, p.r * 0.28, 0, TAU);
        ctx.arc(p.x + p.r * 0.38, p.y - 1, p.r * 0.28, 0, TAU);
        ctx.fill();
        break;
      }
      case 'axe': {
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rot);
        ctx.strokeStyle = '#7a5230';
        ctx.lineWidth = 4;
        ctx.beginPath();
        ctx.moveTo(0, p.r);
        ctx.lineTo(0, -p.r);
        ctx.stroke();
        ctx.fillStyle = p.color;
        ctx.strokeStyle = '#596274';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.moveTo(0, -p.r * 0.9);
        ctx.quadraticCurveTo(p.r * 1.2, -p.r * 1.1, p.r * 0.9, -p.r * 0.05);
        ctx.quadraticCurveTo(p.r * 0.5, -p.r * 0.3, 0, -p.r * 0.2);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.restore();
        break;
      }
      default: {
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r, 0, TAU);
        ctx.fill();
      }
    }
  },

  enemyBullet(ctx, b) {
    ctx.fillStyle = 'rgba(214, 69, 112, 0.35)';
    ctx.beginPath();
    ctx.arc(b.x, b.y, b.r * 1.8, 0, TAU);
    ctx.fill();
    ctx.fillStyle = b.color;
    ctx.beginPath();
    ctx.arc(b.x, b.y, b.r, 0, TAU);
    ctx.fill();
    ctx.fillStyle = '#fff0f4';
    ctx.beginPath();
    ctx.arc(b.x, b.y, b.r * 0.45, 0, TAU);
    ctx.fill();
  },

  // ---------- Coletáveis ----------
  gemSprites: null,

  // Desenha os três tamanhos de cristal uma vez em canvases pequenos
  buildGemSprites() {
    const defs = [[5, '#5fd3a8'], [6.5, '#5aa9ff'], [8, '#c084ff']];
    this.gemSprites = defs.map(([s, color]) => {
      const S = 2;
      const w = Math.ceil(s * 2 + 4), h = Math.ceil(s * 2.6 + 4);
      const c = document.createElement('canvas');
      c.width = w * S;
      c.height = h * S;
      const g = c.getContext('2d');
      g.scale(S, S);
      g.translate(w / 2, h / 2);
      g.fillStyle = color;
      g.strokeStyle = 'rgba(0,0,0,0.5)';
      g.lineWidth = 1.5;
      g.beginPath();
      g.moveTo(0, -s * 1.3);
      g.lineTo(s, 0);
      g.lineTo(0, s * 1.3);
      g.lineTo(-s, 0);
      g.closePath();
      g.fill();
      g.stroke();
      g.fillStyle = 'rgba(255,255,255,0.55)';
      g.beginPath();
      g.moveTo(0, -s * 1.3);
      g.lineTo(s * 0.4, -s * 0.2);
      g.lineTo(-s * 0.3, 0);
      g.closePath();
      g.fill();
      return { canvas: c, w, h };
    });
  },

  pickup(ctx, p, t) {
    const bob = Math.sin(t * 4 + p.t) * 2;
    switch (p.kind) {
      case 'gem': {
        if (!this.gemSprites) this.buildGemSprites();
        const spr = this.gemSprites[p.value >= 8 ? 2 : p.value >= 3 ? 1 : 0];
        ctx.drawImage(spr.canvas, p.x - spr.w / 2, p.y - spr.h / 2 + bob, spr.w, spr.h);
        break;
      }
      case 'heart': {
        const y = p.y + bob;
        ctx.fillStyle = '#e5484d';
        ctx.strokeStyle = '#5a1418';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.moveTo(p.x, y + 7);
        ctx.bezierCurveTo(p.x - 12, y - 2, p.x - 6, y - 11, p.x, y - 4);
        ctx.bezierCurveTo(p.x + 6, y - 11, p.x + 12, y - 2, p.x, y + 7);
        ctx.fill();
        ctx.stroke();
        break;
      }
      case 'chest': {
        const y = p.y + bob;
        ctx.fillStyle = 'rgba(242, 193, 78, 0.25)';
        ctx.beginPath();
        ctx.arc(p.x, y, 26 + Math.sin(t * 5) * 3, 0, TAU);
        ctx.fill();
        ctx.fillStyle = '#8a5a2b';
        ctx.strokeStyle = '#3d2410';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.roundRect(p.x - 15, y - 10, 30, 20, 4);
        ctx.fill();
        ctx.stroke();
        ctx.fillStyle = '#f2c14e';
        ctx.fillRect(p.x - 15, y - 3, 30, 4);
        ctx.fillRect(p.x - 3, y - 5, 6, 8);
        break;
      }
    }
  },

  // ---------- Cenário (pré-renderizado uma vez) ----------
  buildFloor() {
    const M = 240;
    const W = ARENA.w, H = ARENA.h;
    const c = document.createElement('canvas');
    c.width = W + M * 2;
    c.height = H + M * 2;
    const g = c.getContext('2d');
    const rng = mulberry32(1337);

    g.fillStyle = '#07050a';
    g.fillRect(0, 0, c.width, c.height);
    g.translate(M, M);

    g.fillStyle = '#1e1622';
    g.fillRect(0, 0, W, H);

    for (let i = 0; i < 1100; i++) {
      g.fillStyle = rng() < 0.45 ? 'rgba(255, 220, 230, 0.02)' : 'rgba(0, 0, 0, 0.07)';
      g.beginPath();
      g.arc(rng() * W, rng() * H, 8 + rng() * 60, 0, TAU);
      g.fill();
    }

    // lajes gastas
    g.strokeStyle = 'rgba(0, 0, 0, 0.22)';
    g.lineWidth = 2;
    const T = 120;
    for (let y = 0; y <= H; y += T) {
      for (let x = 0; x <= W; x += T) {
        if (rng() < 0.55) g.strokeRect(x + rng() * 6, y + rng() * 6, T - rng() * 10, T - rng() * 10);
      }
    }

    // rachaduras com brasas da Calamidade
    for (let i = 0; i < 30; i++) {
      let x = rng() * W, y = rng() * H, a = rng() * TAU;
      const pts = [[x, y]];
      const n = 6 + Math.floor(rng() * 10);
      for (let j = 0; j < n; j++) {
        a += (rng() - 0.5) * 1.3;
        const len = 14 + rng() * 28;
        x += Math.cos(a) * len;
        y += Math.sin(a) * len;
        pts.push([x, y]);
      }
      const stroke = (style, width) => {
        g.strokeStyle = style;
        g.lineWidth = width;
        g.lineJoin = 'round';
        g.beginPath();
        pts.forEach(([px, py], k) => (k ? g.lineTo(px, py) : g.moveTo(px, py)));
        g.stroke();
      };
      stroke('rgba(255, 90, 40, 0.07)', 12);
      stroke('rgba(0, 0, 0, 0.6)', 4);
      stroke('rgba(255, 120, 50, 0.55)', 1.4);
    }

    // pedras e ossos
    for (let i = 0; i < 140; i++) {
      const x = rng() * W, y = rng() * H, r = 3 + rng() * 8;
      g.fillStyle = '#2d2433';
      g.beginPath();
      g.ellipse(x, y, r, r * 0.75, rng() * TAU, 0, TAU);
      g.fill();
      g.fillStyle = 'rgba(255,255,255,0.05)';
      g.beginPath();
      g.ellipse(x - r * 0.2, y - r * 0.25, r * 0.5, r * 0.3, 0, 0, TAU);
      g.fill();
    }
    for (let i = 0; i < 26; i++) {
      const x = rng() * W, y = rng() * H, a = rng() * TAU;
      g.save();
      g.translate(x, y);
      g.rotate(a);
      g.fillStyle = 'rgba(220, 210, 190, 0.18)';
      g.fillRect(-9, -1.5, 18, 3);
      g.beginPath();
      g.arc(-9, -2, 2.5, 0, TAU);
      g.arc(-9, 2, 2.5, 0, TAU);
      g.arc(9, -2, 2.5, 0, TAU);
      g.arc(9, 2, 2.5, 0, TAU);
      g.fill();
      g.restore();
    }

    // muralha da arena
    g.strokeStyle = '#2c1c33';
    g.lineWidth = 18;
    g.strokeRect(-9, -9, W + 18, H + 18);
    g.strokeStyle = 'rgba(255, 106, 61, 0.45)';
    g.lineWidth = 2;
    g.strokeRect(1, 1, W - 2, H - 2);

    return { canvas: c, margin: M };
  },
};
