extends WeaponBase
## Thorvald: martelo arremessado que atravessa tudo e volta para a mão.


func _init() -> void:
	name = "Martelo Trovejante"
	desc = "Arremessado contra o inimigo, atravessa tudo e volta para a mão."
	icon = "hammer"
	color = Color("aeb6c4")
	hero_only = "thorvald"


func stats(lv: int) -> Dictionary:
	return {"damage": 17 + 7 * lv, "cooldown": 1.6 - 0.08 * lv, "count": 1 + (1 if lv >= 4 else 0), "range": 520}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var t := game.nearest_enemy(p.position, s.range)
	if t == null:
		return false
	var base := (t.pos - p.position).angle()
	for a in fan(base, total_count(p, s), 0.35):
		game.add_projectile({"kind": "hammer", "pos": p.position, "vel": Vector2.from_angle(a) * 600.0, "r": 15.0,
			"damage": s.damage, "pierce": 999, "boomerang": 0.42, "spin": 14.0, "knockback": 200.0, "life": 3.0, "color": color})
	Sfx.play("swing")
	return true
