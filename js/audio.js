'use strict';
// Efeitos sonoros sintetizados com WebAudio (nenhum arquivo de áudio necessário)

const Sfx = {
  ctx: null,
  master: null,
  noiseBuf: null,
  muted: storageGet('hvc-muted', false),
  last: {},
  volume: 0.22,

  // Navegadores só liberam áudio depois de uma interação do jogador
  unlock() {
    if (this.ctx) {
      if (this.ctx.state === 'suspended') this.ctx.resume();
      return;
    }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    try {
      this.ctx = new AC();
      this.master = this.ctx.createGain();
      this.master.gain.value = this.muted ? 0 : this.volume;
      this.master.connect(this.ctx.destination);
      const len = this.ctx.sampleRate;
      this.noiseBuf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
      const data = this.noiseBuf.getChannelData(0);
      for (let i = 0; i < len; i++) data[i] = Math.random() * 2 - 1;
    } catch (e) {
      this.ctx = null;
    }
  },

  setMuted(m) {
    this.muted = m;
    storageSet('hvc-muted', m);
    if (this.master) this.master.gain.value = m ? 0 : this.volume;
  },

  tone(freq, dur, type = 'square', vol = 0.3, slide = 0, delay = 0) {
    const c = this.ctx;
    const t = c.currentTime + delay;
    const o = c.createOscillator();
    const g = c.createGain();
    o.type = type;
    o.frequency.setValueAtTime(freq, t);
    if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(20, freq * slide), t + dur);
    g.gain.setValueAtTime(vol, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + dur);
    o.connect(g);
    g.connect(this.master);
    o.start(t);
    o.stop(t + dur + 0.02);
  },

  noise(dur, vol = 0.3, freq = 1200) {
    const c = this.ctx;
    const t = c.currentTime;
    const src = c.createBufferSource();
    src.buffer = this.noiseBuf;
    const f = c.createBiquadFilter();
    f.type = 'lowpass';
    f.frequency.value = freq;
    const g = c.createGain();
    g.gain.setValueAtTime(vol, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + dur);
    src.connect(f);
    f.connect(g);
    g.connect(this.master);
    src.start(t);
    src.stop(t + dur);
  },

  play(name) {
    if (!this.ctx || this.muted) return;
    const now = performance.now();
    const gap = { hit: 50, kill: 40, pickup: 30, shoot: 70, swing: 90, zap: 80, explode: 90 }[name] || 0;
    if (gap && now - (this.last[name] || 0) < gap) return;
    this.last[name] = now;
    switch (name) {
      case 'hit': this.tone(rand(170, 230), 0.05, 'square', 0.05, 0.5); break;
      case 'kill': this.noise(0.07, 0.08, 900); break;
      case 'pickup': this.tone(rand(900, 1150), 0.05, 'sine', 0.06, 1.4); break;
      case 'shoot': this.tone(rand(500, 600), 0.06, 'triangle', 0.05, 0.6); break;
      case 'swing': this.noise(0.09, 0.07, 2600); break;
      case 'zap': this.tone(1400, 0.08, 'sawtooth', 0.05, 0.3); break;
      case 'explode': this.noise(0.3, 0.18, 500); break;
      case 'hurt': this.tone(150, 0.22, 'sawtooth', 0.2, 0.4); break;
      case 'ability': this.tone(260, 0.35, 'sawtooth', 0.12, 3); this.noise(0.3, 0.1, 2000); break;
      case 'levelup': [523, 659, 784, 1046].forEach((f, i) => this.tone(f, 0.14, 'triangle', 0.16, 0, i * 0.07)); break;
      case 'buy': this.tone(660, 0.08, 'triangle', 0.16); this.tone(990, 0.1, 'triangle', 0.16, 0, 0.06); break;
      case 'deny': this.tone(120, 0.14, 'square', 0.1); break;
      case 'wave': this.tone(330, 0.5, 'triangle', 0.16, 2); break;
      case 'boss': this.tone(70, 1.2, 'sawtooth', 0.22, 0.6); this.noise(1, 0.12, 300); break;
      case 'chest': [392, 523, 659, 784, 1046].forEach((f, i) => this.tone(f, 0.12, 'square', 0.08, 0, i * 0.05)); break;
      case 'death': this.tone(220, 1, 'sawtooth', 0.2, 0.2); break;
      case 'victory': [523, 659, 784, 1046, 784, 1046].forEach((f, i) => this.tone(f, 0.22, 'triangle', 0.18, 0, i * 0.12)); break;
    }
  },
};
