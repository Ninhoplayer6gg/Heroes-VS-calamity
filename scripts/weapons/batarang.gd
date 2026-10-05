extends WeaponBase
## Vigia Noturno: bumerangues em forma de morcego que ricocheteiam entre inimigos.


func _init() -> void:
	name = "Bumerangues Táticos"
	desc = "Ricocheteiam de inimigo em inimigo."
	icon = "bat"
	color = Color("c9cfd8")
	hero_only = "night_watch"


func stats(lv: int) -> Dictionary:
	return {"damage": 9 + 4 * lv, "cooldown": 0.95 - 0.05 * lv, "bounces": 1 + lv / 2, "count": 2 + (1 if lv >= 4 else 0), "range": 460}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var t := game.nearest_enemy(p.position, s.range)
	if t == null:
		return false
	var base := (t.pos - p.position).angle()
	for a in fan(base, total_count(p, s), 0.3):
		game.add_projectile({"kind": "batarang", "pos": p.position, "vel": Vector2.from_angle(a) * 560.0, "r": 9.0,
			"damage": s.damage, "bounces": s.bounces, "spin": 16.0, "life": 1.5, "color": color})
	Sfx.play("shoot")
	return true
