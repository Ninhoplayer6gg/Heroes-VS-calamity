'use strict';
// Entrada: teclado (WASD/setas) e joystick virtual para toque

const Input = {
  keys: new Set(),
  joy: { active: false, id: null, baseX: 0, baseY: 0, x: 0, y: 0 },
  JOY_MAX: 55,
  abilityHeld: false,
  onPause: null,

  init(canvas) {
    window.addEventListener('keydown', e => {
      if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) e.preventDefault();
      this.keys.add(e.code);
      if ((e.code === 'Escape' || e.code === 'KeyP') && !e.repeat && this.onPause) this.onPause();
    });
    window.addEventListener('keyup', e => this.keys.delete(e.code));
    window.addEventListener('blur', () => this.reset());

    // Joystick flutuante: nasce onde o dedo toca
    canvas.addEventListener('pointerdown', e => {
      if (e.pointerType === 'mouse' || this.joy.active) return;
      e.preventDefault();
      const j = this.joy;
      j.active = true;
      j.id = e.pointerId;
      j.baseX = j.x = e.clientX;
      j.baseY = j.y = e.clientY;
      try { canvas.setPointerCapture(e.pointerId); } catch (err) { /* ignorado */ }
    });
    canvas.addEventListener('pointermove', e => {
      const j = this.joy;
      if (!j.active || e.pointerId !== j.id) return;
      j.x = e.clientX;
      j.y = e.clientY;
      const dx = j.x - j.baseX, dy = j.y - j.baseY;
      const l = Math.hypot(dx, dy);
      if (l > this.JOY_MAX) {
        j.baseX = j.x - (dx / l) * this.JOY_MAX;
        j.baseY = j.y - (dy / l) * this.JOY_MAX;
      }
    });
    const end = e => {
      if (e.pointerId === this.joy.id) this.joy.active = false;
    };
    canvas.addEventListener('pointerup', end);
    canvas.addEventListener('pointercancel', end);

    const btn = document.getElementById('btn-ability');
    btn.addEventListener('pointerdown', e => { e.preventDefault(); this.abilityHeld = true; });
    ['pointerup', 'pointerleave', 'pointercancel'].forEach(ev => btn.addEventListener(ev, () => { this.abilityHeld = false; }));
  },

  reset() {
    this.keys.clear();
    this.abilityHeld = false;
    this.joy.active = false;
  },

  getMove() {
    const k = this.keys;
    let x = 0, y = 0;
    if (k.has('KeyA') || k.has('ArrowLeft')) x -= 1;
    if (k.has('KeyD') || k.has('ArrowRight')) x += 1;
    if (k.has('KeyW') || k.has('ArrowUp')) y -= 1;
    if (k.has('KeyS') || k.has('ArrowDown')) y += 1;
    if (x || y) {
      const l = Math.hypot(x, y);
      return { x: x / l, y: y / l };
    }
    const j = this.joy;
    if (j.active) {
      const dx = j.x - j.baseX, dy = j.y - j.baseY;
      const l = Math.hypot(dx, dy);
      if (l < 6) return { x: 0, y: 0 };
      const m = Math.min(l, this.JOY_MAX) / this.JOY_MAX;
      return { x: (dx / l) * m, y: (dy / l) * m };
    }
    return { x: 0, y: 0 };
  },

  isAbilityDown() {
    return this.abilityHeld || this.keys.has('Space') || this.keys.has('KeyE') || this.keys.has('KeyQ');
  },

  drawJoystick(ctx) {
    const j = this.joy;
    if (!j.active) return;
    ctx.save();
    ctx.globalAlpha = 0.5;
    ctx.strokeStyle = '#efe6dc';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(j.baseX, j.baseY, this.JOY_MAX, 0, TAU);
    ctx.stroke();
    ctx.fillStyle = '#efe6dc';
    ctx.beginPath();
    ctx.arc(j.x, j.y, 22, 0, TAU);
    ctx.fill();
    ctx.restore();
  },
};
