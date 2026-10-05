class_name WeaponDB
## Registro de todas as armas. Para criar uma arma nova, crie o script em
## scripts/weapons/ e adicione uma linha aqui.

const SCRIPTS := {
	# Exclusivas de heróis
	"heat_vision": preload("res://scripts/weapons/heat_vision.gd"),
	"ring_constructs": preload("res://scripts/weapons/ring_constructs.gd"),
	"thunder_hammer": preload("res://scripts/weapons/thunder_hammer.gd"),
	"repulsor": preload("res://scripts/weapons/repulsor.gd"),
	"speed_trail": preload("res://scripts/weapons/speed_trail.gd"),
	"golden_lasso": preload("res://scripts/weapons/golden_lasso.gd"),
	"batarang": preload("res://scripts/weapons/batarang.gd"),
	"web_shooter": preload("res://scripts/weapons/web_shooter.gd"),
	# Disponíveis para todos
	"energy_sword": preload("res://scripts/weapons/energy_sword.gd"),
	"plasma_grenade": preload("res://scripts/weapons/plasma_grenade.gd"),
	"combat_drone": preload("res://scripts/weapons/combat_drone.gd"),
	"tesla_coil": preload("res://scripts/weapons/tesla_coil.gd"),
	"force_field": preload("res://scripts/weapons/force_field.gd"),
	"satellites": preload("res://scripts/weapons/satellites.gd"),
}

static var _cache := {}


static func get_weapon(id: String) -> WeaponBase:
	if not _cache.has(id):
		var w: WeaponBase = SCRIPTS[id].new()
		w.id = id
		_cache[id] = w
	return _cache[id]


static func all_ids() -> Array:
	return SCRIPTS.keys()
