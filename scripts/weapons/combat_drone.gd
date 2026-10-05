extends WeaponBase
## Drone de Combate: drones flutuam ao seu lado e atiram no inimigo mais próximo.


func _init() -> void:
	name = "Drone de Combate"
	desc = "Drones flutuam ao seu lado atirando sem parar."
	icon = "drone"
	color = Color("9aa6b8")


func stats(lv: int) -> Dictionary:
	return {"damage": 7 + 3 * lv, "cooldown": 0.9 - 0.06 * lv, "count": [1, 1, 2, 2, 3][lv - 1], "range": 520}


func drone_offset(game: Game, i: int, n: int) -> Vector2:
	var a := game.time * 1.4 + TAU * i / n
	return Vector2(cos(a) * 42.0, sin(a) * 18.0 - 34.0)


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var n := total_count(p, s)
	var fired := false
	for i in n:
		var from := p.position + drone_offset(game, i, n)
		var t := game.nearest_enemy(from, s.range)
		if t == null:
			continue
		fired = true
		var dir := (t.pos - from).normalized()
		game.add_projectile({"kind": "drone_bolt", "pos": from, "vel": dir * 700.0, "r": 4.0, "damage": s.damage, "life": 1.0, "color": color})
	if fired:
		Sfx.play("laser")
	return fired


func draw_over(ci: CanvasItem, p: Player, _slot: WeaponSlot, s: Dictionary) -> void:
	var n := total_count(p, s)
	for i in n:
		Icons.draw(ci, "drone", drone_offset(Game.I, i, n), 11.0, color)
