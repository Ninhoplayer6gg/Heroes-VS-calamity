extends WeaponBase
## Armadura Rubra: rajadas de energia das mãos que explodem ao acertar.


func _init() -> void:
	name = "Repulsores"
	desc = "Rajadas de energia rápidas que explodem ao acertar."
	icon = "palm"
	color = Color("8fd8ff")
	hero_only = "crimson_armor"


func stats(lv: int) -> Dictionary:
	return {"damage": 11 + 5 * lv, "cooldown": 0.75 - 0.05 * lv, "count": 1 + (1 if lv >= 3 else 0) + (1 if lv >= 5 else 0), "radius": 26 + 4 * lv, "range": 560}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var t := game.nearest_enemy(p.position, s.range)
	if t == null:
		return false
	var base := (t.pos - p.position).angle()
	for a in fan(base, total_count(p, s), 0.12):
		game.add_projectile({"kind": "repulsor", "pos": p.position, "vel": Vector2.from_angle(a) * 760.0, "r": 6.0,
			"damage": s.damage, "explode": s.radius * p.stats.area, "life": 1.0, "color": color})
	Sfx.play("shoot")
	return true
