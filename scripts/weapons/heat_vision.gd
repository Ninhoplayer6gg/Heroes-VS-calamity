extends WeaponBase
## Titã Solar: raios dos olhos que atravessam todos os inimigos em linha reta.


func _init() -> void:
	name = "Visão Térmica"
	desc = "Raios dos olhos que atravessam tudo em linha reta."
	icon = "eye"
	color = Color("ff3b3b")
	hero_only = "solar_titan"


func stats(lv: int) -> Dictionary:
	return {"damage": 10 + 6 * lv, "cooldown": 1.15 - 0.07 * lv, "range": 400 + 20 * lv, "count": 1}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var first := game.nearest_enemy(p.position, s.range)
	if first == null:
		return false
	var used := {}
	for i in total_count(p, s):
		var target := first if i == 0 else game.random_enemy(p.position, s.range, used)
		if target == null:
			break
		used[target] = true
		var eye := p.position + Vector2(p.facing * 4.0, -5.0)
		var dir := (target.pos - eye).normalized()
		var end: Vector2 = eye + dir * s.range
		game.line_damage(eye, end, 14.0 * p.stats.area, s.damage, {"knockback": 60.0})
		var side := Vector2(-dir.y, dir.x) * 4.0
		game.add_fx(Fx.Beam.new(eye + side, end + side, color, 3.0))
		game.add_fx(Fx.Beam.new(eye - side, end - side, color, 3.0))
	Sfx.play("laser")
	return true
