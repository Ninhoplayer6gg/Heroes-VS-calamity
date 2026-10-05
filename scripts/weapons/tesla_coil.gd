extends WeaponBase
## Bobina Tesla: raio instantâneo que salta entre inimigos próximos.


func _init() -> void:
	name = "Bobina Tesla"
	desc = "Raio instantâneo que salta entre inimigos próximos."
	icon = "coil"
	color = Color("7fe9ff")


func stats(lv: int) -> Dictionary:
	return {"damage": 12 + 6 * lv, "cooldown": 1.3 - 0.07 * lv, "chains": 2 + lv, "range": 380}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var first := game.nearest_enemy(p.position, s.range)
	if first == null:
		return false
	var used := {}
	for b in 1 + int(p.stats.projectiles):
		var cur := first if b == 0 else game.random_enemy(p.position, s.range, used)
		if cur == null:
			break
		var pts := [p.position + Vector2(0, -10)]
		for i in s.chains + 1:
			if cur == null:
				break
			used[cur] = true
			pts.append(cur.pos)
			game.hit_enemy(cur, s.damage, {"knockback": 40.0})
			cur = game.nearest_enemy(cur.pos, 170.0, used)
		game.add_fx(Fx.Lightning.new(pts, color))
	Sfx.play("zap")
	return true
