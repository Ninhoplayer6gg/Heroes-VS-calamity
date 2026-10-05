extends WeaponBase
## Aracnídeo: disparos de teia que atravessam e deixam os inimigos lentos.


func _init() -> void:
	name = "Lançador de Teia"
	desc = "Teias que atravessam inimigos e os deixam lentos."
	icon = "web"
	color = Color("f4f4f8")
	hero_only = "arachnid"


func stats(lv: int) -> Dictionary:
	return {"damage": 8 + 4 * lv, "cooldown": 0.8 - 0.05 * lv, "pierce": 1 + lv / 2, "count": 1 + (1 if lv >= 3 else 0) + (1 if lv >= 5 else 0),
		"duration": 1.5 + 0.25 * lv, "range": 520}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var t := game.nearest_enemy(p.position, s.range)
	if t == null:
		return false
	var base := (t.pos - p.position).angle()
	for a in fan(base, total_count(p, s), 0.14):
		game.add_projectile({"kind": "web", "pos": p.position, "vel": Vector2.from_angle(a) * 620.0, "r": 7.0,
			"damage": s.damage, "pierce": s.pierce, "slow": 0.5, "slow_time": s.duration, "spin": 6.0, "life": 1.1, "color": color})
	Sfx.play("web")
	return true
