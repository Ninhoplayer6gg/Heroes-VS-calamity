extends WeaponBase
## Campo de Força: queima continuamente os inimigos ao seu redor.


func _init() -> void:
	name = "Campo de Força"
	desc = "Fere continuamente os inimigos ao seu redor."
	icon = "field"
	color = Color("6fb6ff")


func stats(lv: int) -> Dictionary:
	return {"damage": 4 + 3 * lv, "cooldown": 0.5, "radius": 70 + 12 * lv}


func fire(game: Game, p: Player, _slot: WeaponSlot, s: Dictionary) -> bool:
	game.damage_area(p.position, s.radius * p.stats.area, s.damage, {"knockback": 30.0})
	return true


func draw_under(ci: CanvasItem, p: Player, _slot: WeaponSlot, s: Dictionary) -> void:
	var radius: float = s.radius * p.stats.area
	var t := Game.I.time
	ci.draw_circle(Vector2.ZERO, radius, Color(color, 0.1), true, -1.0, true)
	for i in 6:
		var a := t * 0.8 + TAU * i / 6.0
		ci.draw_arc(Vector2.ZERO, radius, a, a + 0.6, 8, Color(color, 0.55), 2.0, true)
