class_name HeroDB
## Lista de heróis jogáveis, na ordem do menu. Para adicionar um herói,
## crie o script em scripts/heroes/ e inclua aqui.

const SCRIPTS := [
	preload("res://scripts/heroes/solar_titan.gd"),
	preload("res://scripts/heroes/emerald_sentinel.gd"),
	preload("res://scripts/heroes/thorvald.gd"),
	preload("res://scripts/heroes/crimson_armor.gd"),
	preload("res://scripts/heroes/scarlet_bolt.gd"),
	preload("res://scripts/heroes/amazon.gd"),
	preload("res://scripts/heroes/night_watch.gd"),
	preload("res://scripts/heroes/arachnid.gd"),
]

static var _all: Array = []


static func all() -> Array:
	if _all.is_empty():
		for s in SCRIPTS:
			_all.append(s.new())
	return _all


static func find(id: String) -> HeroBase:
	for h in all():
		if h.id == id:
			return h
	return null
