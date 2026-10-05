extends WeaponBase
## Espada de Energia: golpe em arco que acerta todos à frente e empurra.


func _init() -> void:
	name = "Espada de Energia"
	desc = "Golpe em arco que acerta todos à frente e empurra."
	icon = "sword"
	color = Color("9ff3ff")


func stats(lv: int) -> Dictionary:
	return {"damage": 14 + 7 * lv, "cooldown": 1.05 - 0.07 * lv, "range": 115 + 5 * lv, "arc": 1.7 + 0.15 * lv}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var reach: float = s.range * p.stats.area
	var t := game.nearest_enemy(p.position, reach + 40.0)
	if t == null:
		return false
	var base := (t.pos - p.position).angle()
	var n := 1 + int(p.stats.projectiles)
	for i in n:
		var a := base + TAU * i / n
		game.cone_damage(p.position, reach, a, s.arc, s.damage, {"knockback": 280.0})
		game.add_fx(Fx.Slash.new(p, a, reach, s.arc, color))
	Sfx.play("swing")
	return true
