extends WeaponBase
## Granada de Plasma: projétil que explode em área ao atingir.


func _init() -> void:
	name = "Granada de Plasma"
	desc = "Explode em área ao atingir o inimigo."
	icon = "grenade"
	color = Color("b67cff")


func stats(lv: int) -> Dictionary:
	return {"damage": 16 + 8 * lv, "cooldown": 1.4 - 0.1 * lv, "radius": 42 + 6 * lv, "count": 2 if lv >= 4 else 1, "range": 520}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var t := game.nearest_enemy(p.position, s.range)
	if t == null:
		return false
	var base := (t.pos - p.position).angle()
	for a in fan(base, total_count(p, s), 0.18):
		game.add_projectile({"kind": "grenade", "pos": p.position, "vel": Vector2.from_angle(a) * 400.0, "r": 9.0,
			"damage": s.damage, "explode": s.radius * p.stats.area, "life": 1.6, "color": color})
	Sfx.play("shoot")
	return true
