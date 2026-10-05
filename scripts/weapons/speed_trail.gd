extends WeaponBase
## Relâmpago Escarlate: ao correr, deixa um rastro elétrico que fere quem tocar.
## Também solta faíscas no inimigo mais próximo de tempos em tempos.


func _init() -> void:
	name = "Rastro Elétrico"
	desc = "Correndo, você deixa um rastro de raios que fere quem tocar e solta faíscas em cadeia."
	icon = "bolt"
	color = Color("ffd23f")
	hero_only = "scarlet_bolt"
	uses_cooldown = false


func stats(lv: int) -> Dictionary:
	return {"damage": 8 + 4 * lv, "duration": 0.9 + 0.15 * lv, "radius": 22 + 2 * lv, "cooldown": 1.0 - 0.08 * lv, "chains": 1 + lv / 2}


func update(game: Game, p: Player, slot: WeaponSlot, s: Dictionary, dt: float) -> void:
	var trail: Array = slot.data.get("trail", [])
	slot.data["trail"] = trail
	slot.data["drop"] = slot.data.get("drop", 0.0) - dt
	if p.moving and slot.data.drop <= 0.0:
		slot.data.drop = 0.05
		trail.append([p.position, game.time])
	while not trail.is_empty() and game.time - trail[0][1] > s.duration:
		trail.pop_front()
	var width: float = s.radius * p.stats.area
	for point in trail:
		for e in game.query(point[0], width + 64.0):
			if e.dead or game.time - e.trail_hit < 0.3:
				continue
			if point[0].distance_to(e.pos) < width + e.r:
				e.trail_hit = game.time
				game.hit_enemy(e, s.damage, {"knockback": 40.0})
	# faíscas
	slot.data["zap"] = slot.data.get("zap", 0.5) - dt * p.stats.attack_speed
	if slot.data.zap <= 0.0:
		var t := game.nearest_enemy(p.position, 300.0)
		if t:
			slot.data.zap = s.cooldown
			var used := {}
			var pts := [p.position]
			for i in s.chains + 1:
				if t == null:
					break
				used[t] = true
				pts.append(t.pos)
				game.hit_enemy(t, s.damage * 2.0, {"knockback": 80.0})
				t = game.nearest_enemy(t.pos, 170.0, used)
			game.add_fx(Fx.Lightning.new(pts, color, 0.18, 2.5))
			Sfx.play("zap")
		else:
			slot.data.zap = 0.2


func draw_world(ci: CanvasItem, game: Game, slot: WeaponSlot) -> void:
	var trail: Array = slot.data.get("trail", [])
	if trail.size() < 2:
		return
	var s := stats(slot.level)
	for i in range(1, trail.size()):
		var a: Vector2 = trail[i - 1][0]
		var b: Vector2 = trail[i][0]
		if a.distance_to(b) > 80.0:
			continue
		var k := 1.0 - (game.time - float(trail[i][1])) / float(s.duration)
		var j := Vector2(randf_range(-4, 4), randf_range(-4, 4))
		ci.draw_line(a, b + j, Color(1.0, 0.55, 0.1, 0.35 * k), 14.0 * k + 2.0, true)
		ci.draw_line(a, b + j, Color(1.0, 0.9, 0.3, 0.9 * k), 3.0, true)
