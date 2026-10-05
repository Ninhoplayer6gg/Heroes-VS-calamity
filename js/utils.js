'use strict';
// Configuração global e utilitários matemáticos

const ARENA = { w: 1800, h: 1300 };
const TOTAL_WAVES = 20;
const MAX_WEAPONS = 6;
const MAX_ENEMIES = 220;
const BASE_MOVE_SPEED = 210;
const BOSS_WAVES = { 10: 'herald', 20: 'calamity' };
const REDUCED_MOTION = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

const TAU = Math.PI * 2;

function rand(min, max) { return min + Math.random() * (max - min); }
function randInt(min, max) { return Math.floor(rand(min, max + 1)); }
function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function chance(p) { return Math.random() < p; }
function clamp(v, min, max) { return v < min ? min : v > max ? max : v; }
function lerp(a, b, t) { return a + (b - a) * t; }
function dist2(ax, ay, bx, by) { const dx = bx - ax, dy = by - ay; return dx * dx + dy * dy; }
function dist(ax, ay, bx, by) { return Math.sqrt(dist2(ax, ay, bx, by)); }
function angleTo(ax, ay, bx, by) { return Math.atan2(by - ay, bx - ax); }

// Normaliza um ângulo para o intervalo [-PI, PI]
function normAngle(a) {
  while (a > Math.PI) a -= TAU;
  while (a < -Math.PI) a += TAU;
  return a;
}

// Distância de um ponto até o segmento AB
function distToSegment(px, py, ax, ay, bx, by) {
  const abx = bx - ax, aby = by - ay;
  const len2 = abx * abx + aby * aby;
  const t = len2 ? clamp(((px - ax) * abx + (py - ay) * aby) / len2, 0, 1) : 0;
  return dist(px, py, ax + abx * t, ay + aby * t);
}

function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

// entries: [{ weight, ... }]
function weightedPick(entries) {
  let total = 0;
  for (const e of entries) total += e.weight;
  let r = Math.random() * total;
  for (const e of entries) {
    r -= e.weight;
    if (r <= 0) return e;
  }
  return entries[entries.length - 1];
}

// Gerador pseudoaleatório com semente (para o cenário ser sempre igual)
function mulberry32(seed) {
  return function () {
    seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function fmtNum(v, decimals = 1) {
  return v.toFixed(decimals).replace('.', ',');
}

// Grade espacial: acelera as buscas de inimigos próximos
class SpatialGrid {
  constructor(width, height, cellSize) {
    this.cs = cellSize;
    this.cols = Math.ceil(width / cellSize) + 1;
    this.rows = Math.ceil(height / cellSize) + 1;
    this.cells = Array.from({ length: this.cols * this.rows }, () => []);
  }

  clear() {
    for (const c of this.cells) c.length = 0;
  }

  insert(obj) {
    const cx = clamp(Math.floor(obj.x / this.cs), 0, this.cols - 1);
    const cy = clamp(Math.floor(obj.y / this.cs), 0, this.rows - 1);
    this.cells[cy * this.cols + cx].push(obj);
  }

  query(x, y, r, fn) {
    const cs = this.cs;
    const x0 = clamp(Math.floor((x - r) / cs), 0, this.cols - 1);
    const x1 = clamp(Math.floor((x + r) / cs), 0, this.cols - 1);
    const y0 = clamp(Math.floor((y - r) / cs), 0, this.rows - 1);
    const y1 = clamp(Math.floor((y + r) / cs), 0, this.rows - 1);
    for (let cy = y0; cy <= y1; cy++) {
      for (let cx = x0; cx <= x1; cx++) {
        const cell = this.cells[cy * this.cols + cx];
        for (let i = 0; i < cell.length; i++) fn(cell[i]);
      }
    }
  }
}

function storageGet(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch (e) {
    return fallback;
  }
}

function storageSet(key, value) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch (e) { /* armazenamento indisponível */ }
}
