extends WeaponBase
## Amazona Imortal: laço dourado que varre um arco longo e prende os inimigos.


func _init() -> void:
	name = "Laço Dourado"
	desc = "Varre um arco longo e deixa os inimigos presos por um instante."
	icon = "lasso"
	color = Color("f2c14e")
	hero_only = "amazon"


func stats(lv: int) -> Dictionary:
	return {"damage": 16 + 7 * lv, "cooldown": 1.1 - 0.07 * lv, "range": 190 + 10 * lv, "count": 1}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	var reach: float = s.range * p.stats.area
	var t := game.nearest_enemy(p.position, reach + 30.0)
	if t == null:
		return false
	var base := (t.pos - p.position).angle()
	var n := total_count(p, s)
	for i in n:
		var a := base + TAU * i / n
		game.cone_damage(p.position, reach, a, 1.2, s.damage, {"knockback": 90.0, "root": 0.4})
		game.add_fx(Fx.Lasso.new(p, a, reach, 1.2))
	Sfx.play("swing")
	return true
