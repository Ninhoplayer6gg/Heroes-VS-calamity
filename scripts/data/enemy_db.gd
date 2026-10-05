class_name EnemyDB
## Inimigos comuns e chefes.
##   min_wave           -> primeira onda em que aparece
##   w_base/w_slope/w_min -> peso de sorteio na onda w: max(w_min, w_base + w_slope * w)
##   behavior           -> chase | zigzag | ranged | bomber | charger | phase

const TYPES := {
	"slime": {"id": "slime", "name": "Gosma Cósmica", "hp": 10, "speed": 72, "damage": 7, "radius": 15, "xp": 1,
		"color": Color("7bc96f"), "dark": Color("2f5a2a"), "behavior": "chase", "min_wave": 1, "w_base": 10.0, "w_slope": -0.35, "w_min": 3.0},
	"bat": {"id": "bat", "name": "Morcego Mutante", "hp": 6, "speed": 135, "damage": 5, "radius": 11, "xp": 1,
		"color": Color("8a4fb8"), "dark": Color("3a1a52"), "behavior": "zigzag", "min_wave": 2, "w_base": 5.0, "w_slope": 0.0, "w_min": 0.0},
	"brute": {"id": "brute", "name": "Brutamontes", "hp": 55, "speed": 48, "damage": 14, "radius": 25, "xp": 4,
		"color": Color("c46a3a"), "dark": Color("5a2a12"), "behavior": "chase", "kb_resist": 0.7, "min_wave": 3, "w_base": 2.0, "w_slope": 0.1, "w_min": 0.0},
	"cultist": {"id": "cultist", "name": "Cultista do Caos", "hp": 18, "speed": 70, "damage": 9, "radius": 15, "xp": 2,
		"color": Color("a3324f"), "dark": Color("4a1020"), "behavior": "ranged", "shoot_cooldown": 2.6, "bullet_speed": 210.0,
		"min_wave": 4, "w_base": 2.5, "w_slope": 0.0, "w_min": 0.0},
	"bomber": {"id": "bomber", "name": "Robô-Bomba", "hp": 14, "speed": 115, "damage": 22, "radius": 14, "xp": 2,
		"color": Color("4a4f5c"), "dark": Color("15131a"), "behavior": "bomber", "min_wave": 5, "w_base": 2.5, "w_slope": 0.0, "w_min": 0.0},
	"boar": {"id": "boar", "name": "Besta Infernal", "hp": 35, "speed": 62, "damage": 13, "radius": 19, "xp": 3,
		"color": Color("8a6a4f"), "dark": Color("3d2a1c"), "behavior": "charger", "kb_resist": 0.4, "min_wave": 6, "w_base": 2.5, "w_slope": 0.0, "w_min": 0.0},
	"wraith": {"id": "wraith", "name": "Espectro", "hp": 28, "speed": 95, "damage": 10, "radius": 16, "xp": 3,
		"color": Color("9fd8ff"), "behavior": "phase", "min_wave": 8, "w_base": 3.0, "w_slope": 0.0, "w_min": 0.0},
	"golem": {"id": "golem", "name": "Golem de Magma", "hp": 140, "speed": 40, "damage": 20, "radius": 32, "xp": 8,
		"color": Color("5e6270"), "dark": Color("24262e"), "behavior": "chase", "kb_resist": 0.9, "min_wave": 12, "w_base": -1.4, "w_slope": 0.2, "w_min": 1.0},
}

const BOSSES := {
	"herald": {"id": "herald", "name": "Arauto da Calamidade", "hp": 5500, "speed": 75, "damage": 22, "radius": 46, "xp": 80,
		"color": Color("b23a48"), "behavior": "boss", "attacks": ["ring", "charge", "summon"]},
	"calamity": {"id": "calamity", "name": "A Calamidade", "hp": 40000, "speed": 85, "damage": 30, "radius": 64, "xp": 0,
		"color": Color("d6402e"), "behavior": "boss", "attacks": ["ring", "charge", "summon", "spiral"]},
}


static func weight(d: Dictionary, wave: int) -> float:
	return maxf(d.w_min, d.w_base + d.w_slope * wave)


static func pick_type(wave: int) -> String:
	var entries := []
	for d in TYPES.values():
		if wave >= d.min_wave:
			entries.append({"id": d.id, "weight": weight(d, wave)})
	return U.weighted_pick(entries).id
