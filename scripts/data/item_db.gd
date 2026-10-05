class_name ItemDB
## Melhorias de nível, itens da loja, raridades e formatação de atributos.

## Rótulo, formato e ícone de cada atributo
const STAT_INFO := {
	"max_hp": {"label": "Vida Máx.", "icon": "heart", "color": Color("e5484d")},
	"regen": {"label": "Regeneração", "decimals": 1, "unit": "/s", "icon": "cross", "color": Color("5fd38a")},
	"armor": {"label": "Armadura", "icon": "shield", "color": Color("9fb4cc")},
	"damage": {"label": "Dano", "pct": true, "icon": "sword", "color": Color("ff8a5c")},
	"attack_speed": {"label": "Vel. de Ataque", "pct": true, "icon": "clock", "color": Color("ffd23f")},
	"crit": {"label": "Crítico", "pct": true, "icon": "target", "color": Color("ff5d73")},
	"speed": {"label": "Velocidade", "pct": true, "icon": "speed", "color": Color("7fe9ff")},
	"area": {"label": "Área", "pct": true, "icon": "burst", "color": Color("ff9f1a")},
	"projectiles": {"label": "Projéteis", "icon": "plus", "color": Color("c084ff")},
	"pickup_range": {"label": "Coleta", "icon": "magnet", "color": Color("e5484d")},
	"dodge": {"label": "Esquiva", "pct": true, "icon": "wind", "color": Color("bfeaff")},
	"lifesteal": {"label": "Roubo de Vida", "pct": true, "icon": "drop", "color": Color("c0262d")},
	"cooldown": {"label": "Recarga da Habilidade", "short": "Recarga Hab.", "pct": true, "invert": true, "icon": "bolt", "color": Color("5aa9ff")},
	"xp_gain": {"label": "Experiência", "pct": true, "icon": "gem", "color": Color("5fd3a8")},
	"gold_gain": {"label": "Ouro", "pct": true, "icon": "coin", "color": Color("f2c14e")},
	"luck": {"label": "Sorte", "icon": "clover", "color": Color("6fd36a")},
}

const RARITIES := [
	{"name": "Comum", "color": Color("c9c2cf"), "mult": 1.0},
	{"name": "Raro", "color": Color("5aa9ff"), "mult": 1.6},
	{"name": "Épico", "color": Color("b67cff"), "mult": 2.4},
	{"name": "Lendário", "color": Color("ffa31a"), "mult": 3.5},
]

const LEVEL_UPGRADES := [
	{"stat": "max_hp", "base": 8.0, "name": "Vigor"},
	{"stat": "regen", "base": 0.6, "name": "Recuperação"},
	{"stat": "armor", "base": 1.0, "name": "Couraça"},
	{"stat": "damage", "base": 0.06, "name": "Força"},
	{"stat": "attack_speed", "base": 0.06, "name": "Agilidade"},
	{"stat": "crit", "base": 0.03, "name": "Precisão"},
	{"stat": "speed", "base": 0.04, "name": "Ligeireza"},
	{"stat": "area", "base": 0.06, "name": "Amplitude"},
	{"stat": "pickup_range", "base": 18.0, "name": "Magnetismo"},
	{"stat": "dodge", "base": 0.025, "name": "Reflexos"},
	{"stat": "lifesteal", "base": 0.015, "name": "Vampirismo"},
	{"stat": "cooldown", "base": -0.05, "name": "Concentração"},
	{"stat": "xp_gain", "base": 0.06, "name": "Sabedoria"},
	{"stat": "luck", "base": 4.0, "name": "Sorte"},
]

## Itens da loja. tier = raridade (0 Comum ... 3 Lendário). icon/color: ícone desenhado.
const ITEMS := [
	{"id": "gloves", "name": "Luvas de Combate", "icon": "sword", "tier": 0, "price": 18, "mods": {"damage": 0.1}},
	{"id": "chrono", "name": "Cronômetro Quântico", "icon": "clock", "tier": 0, "price": 18, "mods": {"attack_speed": 0.1}},
	{"id": "boots", "name": "Botas Propulsoras", "icon": "speed", "tier": 0, "price": 16, "mods": {"speed": 0.1}},
	{"id": "visor", "name": "Visor Tático", "icon": "target", "tier": 0, "price": 15, "mods": {"crit": 0.06}},
	{"id": "magnet", "name": "Ímã de Neodímio", "icon": "magnet", "tier": 0, "price": 12, "mods": {"pickup_range": 50.0}},
	{"id": "lucky_coin", "name": "Moeda da Sorte", "icon": "clover", "tier": 0, "price": 14, "mods": {"luck": 12.0}},
	{"id": "kevlar", "name": "Colete de Kevlar", "icon": "shield", "tier": 0, "price": 16, "mods": {"armor": 2.0}},
	{"id": "nanobots", "name": "Nanorrobôs Médicos", "icon": "cross", "tier": 0, "price": 14, "mods": {"regen": 1.2}},
	{"id": "black_card", "name": "Cartão Ilimitado", "icon": "coin", "tier": 0, "price": 15, "mods": {"gold_gain": 0.2}},
	{"id": "supercomputer", "name": "Supercomputador", "icon": "gem", "tier": 0, "price": 15, "mods": {"xp_gain": 0.15}},
	{"id": "serum", "name": "Soro do Supersoldado", "icon": "heart", "tier": 1, "price": 24, "mods": {"max_hp": 25.0, "speed": -0.03}},
	{"id": "symbiote", "name": "Simbionte", "icon": "drop", "tier": 1, "price": 26, "mods": {"lifesteal": 0.04}},
	{"id": "amplifier", "name": "Amplificador de Energia", "icon": "burst", "tier": 1, "price": 24, "mods": {"area": 0.15}},
	{"id": "stealth_cloak", "name": "Manto Furtivo", "icon": "wind", "tier": 1, "price": 26, "mods": {"dodge": 0.07, "max_hp": -5.0}},
	{"id": "power_cell", "name": "Célula de Energia", "icon": "bolt", "tier": 1, "price": 24, "mods": {"cooldown": -0.15}},
	{"id": "war_cry", "name": "Grito de Guerra", "icon": "star", "tier": 1, "price": 28, "mods": {"attack_speed": 0.12, "damage": 0.06}},
	{"id": "duplicator", "name": "Módulo Duplicador", "icon": "plus", "tier": 2, "price": 45, "mods": {"projectiles": 1.0, "damage": -0.08}},
	{"id": "rage_serum", "name": "Soro da Fúria", "icon": "fist", "tier": 2, "price": 40, "mods": {"damage": 0.25, "armor": -2.0}},
	{"id": "exoskeleton", "name": "Exoesqueleto", "icon": "shield", "tier": 2, "price": 42, "mods": {"max_hp": 40.0, "armor": 2.0, "speed": -0.06}},
	{"id": "phoenix_feather", "name": "Pena de Fênix", "icon": "feather", "tier": 2, "price": 50, "mods": {}, "special": "revive", "unique": true,
		"note": "Ao morrer, renasce com 50% da vida (uma vez)."},
	{"id": "calamity_crown", "name": "Coroa da Calamidade", "icon": "crown", "tier": 3, "price": 80, "mods": {"damage": 0.3, "attack_speed": 0.3, "max_hp": -20.0}},
	{"id": "storm_core", "name": "Núcleo da Tempestade", "icon": "bolt", "tier": 3, "price": 75, "mods": {"attack_speed": 0.2, "speed": 0.1, "cooldown": -0.2}},
	{"id": "titan_plate", "name": "Placa de Titânio", "icon": "shield", "tier": 3, "price": 75, "mods": {"armor": 5.0, "max_hp": 30.0, "regen": 2.0}},
	{"id": "quantum_clone", "name": "Clone Quântico", "icon": "plus", "tier": 3, "price": 90, "mods": {"projectiles": 1.0, "area": 0.1}},
]


# ---------- Formatação ----------

## Texto de um modificador, ex.: {"text": "+10% Dano", "good": true}
static func format_mod(key: String, v: float) -> Dictionary:
	var info: Dictionary = STAT_INFO.get(key, {"label": key})
	var sign_txt := "+" if v >= 0.0 else "−"
	var a := absf(v)
	var num := ""
	if info.get("pct", false):
		num = "%d%%" % roundi(a * 100.0)
	elif info.has("decimals"):
		num = U.fmt_num(a, info.decimals) + info.get("unit", "")
	else:
		num = str(roundi(a))
	var good := v < 0.0 if info.get("invert", false) else v > 0.0
	return {"text": "%s%s %s" % [sign_txt, num, info.label], "good": good}


static func format_mods(mods: Dictionary) -> Array:
	var out := []
	for k in mods:
		out.append(format_mod(k, mods[k]))
	return out


static func format_stat_value(key: String, v: float) -> String:
	var info: Dictionary = STAT_INFO.get(key, {})
	if info.get("pct", false):
		return "%d%%" % roundi(v * 100.0)
	if info.has("decimals"):
		return U.fmt_num(v, info.decimals) + info.get("unit", "")
	return str(roundi(v))


# ---------- Sorteios ----------

static func roll_rarity(wave: int, luck: float) -> int:
	var weights := [
		100.0,
		10.0 + wave * 2.2 + luck * 0.5,
		maxf(0.0, (wave - 3) * 1.6) + luck * 0.25,
		maxf(0.0, (wave - 7) * 0.7) + luck * 0.1,
	]
	var entries := []
	for i in weights.size():
		entries.append({"weight": weights[i], "i": i})
	return U.weighted_pick(entries).i


static func round_stat(stat: String, v: float) -> float:
	var info: Dictionary = STAT_INFO.get(stat, {})
	if info.get("pct", false):
		return roundf(v * 100.0) / 100.0
	if info.has("decimals"):
		return roundf(v * 10.0) / 10.0
	return signf(v) * maxf(1.0, roundf(absf(v)))


## Opções são dicionários: kind ("stat" | "weapon" | "item"), name, icon, color,
## rarity, effects e o que aplicar (mods, weapon_id ou item).
static func make_stat_option(up: Dictionary, rarity: int) -> Dictionary:
	var value := round_stat(up.stat, up.base * RARITIES[rarity].mult)
	var mods := {up.stat: value}
	var info: Dictionary = STAT_INFO[up.stat]
	return {"key": "stat:" + up.stat, "kind": "stat", "name": up.name, "icon": info.icon, "color": info.color,
		"rarity": rarity, "effects": format_mods(mods), "mods": mods, "tag": "Atributo"}


static func make_weapon_option(p: Player, id: String) -> Dictionary:
	var w := WeaponDB.get_weapon(id)
	var owned := p.get_weapon(id)
	if owned:
		return {"key": "weapon:" + id, "kind": "weapon", "weapon_id": id, "name": "%s Nv %d" % [w.name, owned.level + 1],
			"rarity": mini(3, owned.level - 1), "effects": w.level_changes(owned.level), "tag": "Melhoria de arma", "level": owned.level + 1}
	return {"key": "weapon:" + id, "kind": "weapon", "weapon_id": id, "name": w.name, "rarity": 0,
		"effects": [{"text": w.desc, "neutral": true}], "tag": "Nova arma", "level": 1}


static func make_item_option(item: Dictionary, wave: int) -> Dictionary:
	var fx := format_mods(item.mods)
	if item.has("note"):
		fx.append({"text": item.note, "good": true})
	var info: Dictionary = STAT_INFO.get(item.mods.keys()[0], {}) if not item.mods.is_empty() else {}
	return {"key": "item:" + item.id, "kind": "item", "item": item, "name": item.name, "icon": item.icon,
		"color": info.get("color", Config.C_GOLD), "rarity": item.tier, "effects": fx, "tag": "Item",
		"price": roundi(item.price * price_scale(wave))}


## Armas que o jogador pode receber: novas (se houver espaço e for permitida) ou melhorias
static func weapon_candidates(p: Player) -> Array:
	var out := []
	for id in WeaponDB.all_ids():
		var w := WeaponDB.get_weapon(id)
		var owned := p.get_weapon(id)
		if owned:
			if owned.level < w.max_level:
				out.append(id)
		elif p.weapons.size() < Config.MAX_WEAPONS and (w.hero_only == "" or w.hero_only == p.hero.id):
			out.append(id)
	return out


static func roll_level_up_options(p: Player, wave: int) -> Array:
	var count := 4 if p.stats.luck >= 40.0 else 3
	var options := []
	var used := {}
	var weapons := weapon_candidates(p)
	weapons.shuffle()
	var guard := 0
	while options.size() < count and guard < 50:
		guard += 1
		var opt: Dictionary
		if not weapons.is_empty() and randf() < 0.3:
			opt = make_weapon_option(p, weapons.pop_back())
		else:
			opt = make_stat_option(LEVEL_UPGRADES.pick_random(), roll_rarity(wave, p.stats.luck))
		if used.has(opt.key):
			continue
		used[opt.key] = true
		options.append(opt)
	return options


static func price_scale(wave: int) -> float:
	return 1.0 + (wave - 1) * 0.22


static func pick_item(p: Player, tier: int) -> Dictionary:
	for t in range(tier, -1, -1):
		var pool := []
		for it in ITEMS:
			if it.tier != t:
				continue
			if it.get("unique", false) and p.items.any(func(o): return o.id == it.id):
				continue
			pool.append(it)
		if not pool.is_empty():
			return pool.pick_random()
	return ITEMS[0]


static func roll_shop_offers(p: Player, wave: int) -> Array:
	var offers := []
	var used := {}
	var guard := 0
	while offers.size() < 4 and guard < 60:
		guard += 1
		var weapons := weapon_candidates(p).filter(func(id): return not used.has("weapon:" + id))
		var offer: Dictionary
		if not weapons.is_empty() and randf() < 0.35:
			var id: String = weapons.pick_random()
			offer = make_weapon_option(p, id)
			var owned := p.get_weapon(id)
			offer["price"] = roundi((18.0 + offer.level * 10.0 if owned else 22.0) * price_scale(wave))
		else:
			offer = make_item_option(pick_item(p, roll_rarity(wave, p.stats.luck)), wave)
		if used.has(offer.key):
			continue
		used[offer.key] = true
		offers.append(offer)
	return offers


static func roll_chest_item(p: Player, wave: int) -> Dictionary:
	return pick_item(p, maxi(1, roll_rarity(wave, p.stats.luck + 20.0)))
