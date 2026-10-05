'use strict';
// Inimigos comuns e chefes.
//   minWave  -> primeira onda em que o inimigo aparece
//   weight() -> peso de sorteio por onda (maior = aparece mais)
//   behavior -> chase | zigzag | ranged | bomber | charger | phase

const ENEMY_TYPES = {
  slime: {
    id: 'slime', name: 'Lodo', hp: 10, speed: 72, damage: 7, radius: 15, xp: 1,
    color: '#7bc96f', dark: '#2f5a2a', behavior: 'chase',
    minWave: 1, weight: w => Math.max(3, 10 - w * 0.35),
  },
  bat: {
    id: 'bat', name: 'Morcego', hp: 6, speed: 135, damage: 5, radius: 11, xp: 1,
    color: '#8a4fb8', dark: '#3a1a52', behavior: 'zigzag',
    minWave: 2, weight: () => 5,
  },
  brute: {
    id: 'brute', name: 'Brutamontes', hp: 55, speed: 48, damage: 14, radius: 25, xp: 4,
    color: '#c46a3a', dark: '#5a2a12', behavior: 'chase', kbResist: 0.7,
    minWave: 3, weight: w => 2 + w * 0.1,
  },
  cultist: {
    id: 'cultist', name: 'Cultista', hp: 18, speed: 70, damage: 9, radius: 15, xp: 2,
    color: '#a3324f', dark: '#4a1020', behavior: 'ranged', shootCooldown: 2.6, bulletSpeed: 210,
    minWave: 4, weight: () => 2.5,
  },
  bomber: {
    id: 'bomber', name: 'Bombinha', hp: 14, speed: 115, damage: 22, radius: 14, xp: 2,
    color: '#3a3644', dark: '#15131a', behavior: 'bomber',
    minWave: 5, weight: () => 2.5,
  },
  boar: {
    id: 'boar', name: 'Javali Infernal', hp: 35, speed: 62, damage: 13, radius: 19, xp: 3,
    color: '#8a6a4f', dark: '#3d2a1c', behavior: 'charger', kbResist: 0.4,
    minWave: 6, weight: () => 2.5,
  },
  wraith: {
    id: 'wraith', name: 'Espectro', hp: 28, speed: 95, damage: 10, radius: 16, xp: 3,
    color: '#9fd8ff', behavior: 'phase',
    minWave: 8, weight: () => 3,
  },
  golem: {
    id: 'golem', name: 'Golem de Magma', hp: 140, speed: 40, damage: 20, radius: 32, xp: 8,
    color: '#5e6270', dark: '#24262e', behavior: 'chase', kbResist: 0.9,
    minWave: 12, weight: w => 1 + (w - 12) * 0.2,
  },
};

const BOSSES = {
  herald: {
    id: 'herald', name: 'Arauto da Calamidade', hp: 5500, speed: 75, damage: 22, radius: 46, xp: 80,
    color: '#b23a48', attacks: ['ring', 'charge', 'summon'],
  },
  calamity: {
    id: 'calamity', name: 'A Calamidade', hp: 40000, speed: 85, damage: 30, radius: 64, xp: 0,
    color: '#d6402e', attacks: ['ring', 'charge', 'summon', 'spiral'],
  },
};
