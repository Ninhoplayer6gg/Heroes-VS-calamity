'use strict';
// Melhorias de nível, itens da loja e raridades

const STAT_INFO = {
  maxHp: { label: 'Vida Máx.' },
  regen: { label: 'Regeneração', unit: '/s', decimals: 1 },
  armor: { label: 'Armadura' },
  damage: { label: 'Dano', pct: true },
  attackSpeed: { label: 'Vel. de Ataque', pct: true },
  crit: { label: 'Crítico', pct: true },
  speed: { label: 'Velocidade', pct: true },
  area: { label: 'Área', pct: true },
  projectiles: { label: 'Projéteis' },
  pickupRange: { label: 'Coleta' },
  dodge: { label: 'Esquiva', pct: true },
  lifesteal: { label: 'Roubo de Vida', pct: true },
  cooldown: { label: 'Recarga da Habilidade', pct: true, invert: true },
  xpGain: { label: 'Experiência', pct: true },
  goldGain: { label: 'Ouro', pct: true },
  luck: { label: 'Sorte' },
};

// Texto de um modificador, ex.: { text: '+10% Dano', good: true }
function formatMod(key, v) {
  const info = STAT_INFO[key] || { label: key };
  const sign = v >= 0 ? '+' : '−';
  const abs = Math.abs(v);
  let num;
  if (info.pct) num = Math.round(abs * 100) + '%';
  else if (info.decimals) num = fmtNum(abs, info.decimals) + (info.unit || '');
  else num = Math.round(abs);
  const good = info.invert ? v < 0 : v > 0;
  return { text: `${sign}${num} ${info.label}`, good };
}

function formatMods(mods) {
  return Object.keys(mods).map(k => formatMod(k, mods[k]));
}

// Valor atual de um atributo, formatado para os painéis
function formatStatValue(key, v) {
  const info = STAT_INFO[key] || {};
  if (info.pct) return Math.round(v * 100) + '%';
  if (info.decimals) return fmtNum(v, info.decimals) + (info.unit || '');
  return String(Math.round(v));
}

const RARITIES = [
  { id: 'common', name: 'Comum', mult: 1 },
  { id: 'rare', name: 'Raro', mult: 1.6 },
  { id: 'epic', name: 'Épico', mult: 2.4 },
  { id: 'legendary', name: 'Lendário', mult: 3.5 },
];

function rollRarity(wave, luck) {
  const weights = [
    100,
    10 + wave * 2.2 + luck * 0.5,
    Math.max(0, (wave - 3) * 1.6) + luck * 0.25,
    Math.max(0, (wave - 7) * 0.7) + luck * 0.1,
  ];
  return weightedPick(weights.map((weight, i) => ({ weight, i }))).i;
}

// ---------- Subir de nível ----------

const LEVEL_UPGRADES = [
  { stat: 'maxHp', base: 8, icon: '❤️', name: 'Vigor' },
  { stat: 'regen', base: 0.6, icon: '💚', name: 'Recuperação' },
  { stat: 'armor', base: 1, icon: '🛡️', name: 'Couraça' },
  { stat: 'damage', base: 0.06, icon: '⚔️', name: 'Força' },
  { stat: 'attackSpeed', base: 0.06, icon: '⏱️', name: 'Agilidade' },
  { stat: 'crit', base: 0.03, icon: '🎯', name: 'Precisão' },
  { stat: 'speed', base: 0.04, icon: '👟', name: 'Ligeireza' },
  { stat: 'area', base: 0.06, icon: '💥', name: 'Amplitude' },
  { stat: 'pickupRange', base: 18, icon: '🧲', name: 'Magnetismo' },
  { stat: 'dodge', base: 0.025, icon: '💨', name: 'Reflexos' },
  { stat: 'lifesteal', base: 0.015, icon: '🩸', name: 'Vampirismo' },
  { stat: 'cooldown', base: -0.05, icon: '🔮', name: 'Concentração' },
  { stat: 'xpGain', base: 0.06, icon: '📖', name: 'Sabedoria' },
  { stat: 'luck', base: 4, icon: '🍀', name: 'Sorte' },
];

function roundStat(stat, v) {
  const info = STAT_INFO[stat] || {};
  if (info.pct) return Math.round(v * 100) / 100;
  if (info.decimals) return Math.round(v * 10) / 10;
  return Math.sign(v) * Math.max(1, Math.round(Math.abs(v)));
}

function makeStatOption(up, rarity) {
  const value = roundStat(up.stat, up.base * RARITIES[rarity].mult);
  const mods = { [up.stat]: value };
  return {
    key: 'stat:' + up.stat,
    kind: 'stat',
    name: up.name,
    icon: up.icon,
    rarity,
    effects: formatMods(mods),
    apply: p => p.addMods(mods),
  };
}

function makeWeaponOption(p, id) {
  const def = WEAPONS[id];
  const owned = p.getWeapon(id);
  if (owned) {
    return {
      key: 'weapon:' + id,
      kind: 'weapon',
      name: `${def.name} Nv ${owned.level + 1}`,
      icon: def.icon,
      rarity: Math.min(3, owned.level - 1),
      effects: weaponLevelChanges(def, owned.level),
      apply: pl => pl.addWeapon(id),
    };
  }
  return {
    key: 'weapon:' + id,
    kind: 'weapon',
    name: def.name,
    icon: def.icon,
    rarity: 0,
    isNew: true,
    effects: [{ text: def.desc, neutral: true }],
    apply: pl => pl.addWeapon(id),
  };
}

// Armas que o jogador pode receber: novas (se houver espaço) ou melhorias
function weaponCandidates(p) {
  const out = [];
  for (const id in WEAPONS) {
    const owned = p.getWeapon(id);
    if (owned ? owned.level < owned.def.maxLevel : p.weapons.length < MAX_WEAPONS) out.push(id);
  }
  return out;
}

function rollLevelUpOptions(p, wave) {
  const count = p.stats.luck >= 40 ? 4 : 3;
  const options = [];
  const used = new Set();
  const weapons = shuffle(weaponCandidates(p));
  let guard = 0;
  while (options.length < count && guard++ < 50) {
    let opt;
    if (weapons.length && chance(0.3)) opt = makeWeaponOption(p, weapons.pop());
    else opt = makeStatOption(pick(LEVEL_UPGRADES), rollRarity(wave, p.stats.luck));
    if (used.has(opt.key)) continue;
    used.add(opt.key);
    options.push(opt);
  }
  return options;
}

// ---------- Loja ----------

const ITEMS = [
  { id: 'whetstone', name: 'Pedra de Amolar', icon: '🔪', tier: 0, price: 18, mods: { damage: 0.1 } },
  { id: 'hourglass', name: 'Ampulheta Rachada', icon: '⏳', tier: 0, price: 18, mods: { attackSpeed: 0.1 } },
  { id: 'winged_boots', name: 'Botas Aladas', icon: '👢', tier: 0, price: 16, mods: { speed: 0.1 } },
  { id: 'hawk_eye', name: 'Olho de Falcão', icon: '👁️', tier: 0, price: 15, mods: { crit: 0.06 } },
  { id: 'magnet', name: 'Ímã Antigo', icon: '🧲', tier: 0, price: 12, mods: { pickupRange: 50 } },
  { id: 'clover', name: 'Trevo de Quatro Folhas', icon: '🍀', tier: 0, price: 14, mods: { luck: 12 } },
  { id: 'iron_helm', name: 'Elmo de Ferro', icon: '⛑️', tier: 0, price: 16, mods: { armor: 2 } },
  { id: 'bandage', name: 'Bandagens', icon: '🩹', tier: 0, price: 14, mods: { regen: 1.2 } },
  { id: 'coin_pouch', name: 'Bolsa de Moedas', icon: '👛', tier: 0, price: 15, mods: { goldGain: 0.2 } },
  { id: 'glasses', name: 'Óculos do Sábio', icon: '👓', tier: 0, price: 15, mods: { xpGain: 0.15 } },
  { id: 'giant_heart', name: 'Coração de Gigante', icon: '💗', tier: 1, price: 24, mods: { maxHp: 25, speed: -0.03 } },
  { id: 'vampire_fang', name: 'Presa de Vampiro', icon: '🦇', tier: 1, price: 26, mods: { lifesteal: 0.04 } },
  { id: 'lens', name: 'Lente de Aumento', icon: '🔍', tier: 1, price: 24, mods: { area: 0.15 } },
  { id: 'shadow_cloak', name: 'Capa Sombria', icon: '🧥', tier: 1, price: 26, mods: { dodge: 0.07, maxHp: -5 } },
  { id: 'arcane_tome', name: 'Tomo Arcano', icon: '📘', tier: 1, price: 24, mods: { cooldown: -0.15 } },
  { id: 'war_drum', name: 'Tambor de Guerra', icon: '🥁', tier: 1, price: 28, mods: { attackSpeed: 0.12, damage: 0.06 } },
  { id: 'quiver', name: 'Aljava Encantada', icon: '🏹', tier: 2, price: 45, mods: { projectiles: 1, damage: -0.08 } },
  { id: 'berserker_mask', name: 'Máscara do Berserker', icon: '👹', tier: 2, price: 40, mods: { damage: 0.25, armor: -2 } },
  { id: 'titan_belt', name: 'Cinto de Titã', icon: '🥋', tier: 2, price: 42, mods: { maxHp: 40, armor: 2, speed: -0.06 } },
  { id: 'phoenix_feather', name: 'Pena de Fênix', icon: '🪶', tier: 2, price: 50, mods: {}, special: 'revive', unique: true, note: 'Ao morrer, renasce com 50% da vida (uma vez).' },
  { id: 'calamity_crown', name: 'Coroa da Calamidade', icon: '👑', tier: 3, price: 80, mods: { damage: 0.3, attackSpeed: 0.3, maxHp: -20 } },
  { id: 'storm_core', name: 'Núcleo da Tempestade', icon: '🔋', tier: 3, price: 75, mods: { attackSpeed: 0.2, speed: 0.1, cooldown: -0.2 } },
  { id: 'dragon_scale', name: 'Escama de Dragão', icon: '🐉', tier: 3, price: 75, mods: { armor: 5, maxHp: 30, regen: 2 } },
  { id: 'twin_soul', name: 'Alma Gêmea', icon: '♊', tier: 3, price: 90, mods: { projectiles: 1, area: 0.1 } },
];

function itemEffects(item) {
  const fx = formatMods(item.mods);
  if (item.note) fx.push({ text: item.note, good: true });
  return fx;
}

function priceScale(wave) { return 1 + (wave - 1) * 0.22; }

function pickItem(p, tier) {
  for (let t = tier; t >= 0; t--) {
    const pool = ITEMS.filter(it => it.tier === t && !(it.unique && p.items.some(o => o.id === it.id)));
    if (pool.length) return pick(pool);
  }
  return ITEMS[0];
}

function rollShopOffers(p, wave) {
  const offers = [];
  const used = new Set();
  let guard = 0;
  while (offers.length < 4 && guard++ < 60) {
    const weapons = weaponCandidates(p).filter(id => !used.has('weapon:' + id));
    let offer;
    if (weapons.length && chance(0.35)) {
      const id = pick(weapons);
      const owned = p.getWeapon(id);
      const level = owned ? owned.level + 1 : 1;
      const opt = makeWeaponOption(p, id);
      offer = { ...opt, price: Math.round((owned ? 18 + level * 10 : 22) * priceScale(wave)) };
    } else {
      const item = pickItem(p, rollRarity(wave, p.stats.luck));
      if (used.has('item:' + item.id)) continue;
      offer = {
        key: 'item:' + item.id,
        kind: 'item',
        name: item.name,
        icon: item.icon,
        rarity: item.tier,
        effects: itemEffects(item),
        price: Math.round(item.price * priceScale(wave)),
        apply: pl => pl.addItem(item),
      };
    }
    if (used.has(offer.key)) continue;
    used.add(offer.key);
    offers.push(offer);
  }
  return offers;
}

function rollChestItem(p, wave) {
  return pickItem(p, Math.max(1, rollRarity(wave, p.stats.luck + 20)));
}
