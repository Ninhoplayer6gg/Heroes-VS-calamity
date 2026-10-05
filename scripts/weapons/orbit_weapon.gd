class_name OrbitWeapon
extends WeaponBase
## Base para armas que giram em volta do jogador e cortam quem encostar.
## As subclasses só mudam números e o desenho de cada peça (draw_piece).


func _init() -> void:
	uses_cooldown = false


func update(game: Game, p: Player, slot: WeaponSlot, s: Dictionary, dt: float) -> void:
	slot.data["angle"] = slot.data.get("angle", 0.0) + s.spin * dt
	var n := total_count(p, s)
	var radius: float = s.radius * p.stats.area
	var pieces := []
	for i in n:
		var a: float = slot.data.angle + TAU * i / n
		var local := Vector2.from_angle(a) * radius
		pieces.append([local, a])
		var world := p.position + local
		for e in game.query(world, 80.0):
			if e.dead or game.time - e.orbit_hit < 0.35:
				continue
			if world.distance_to(e.pos) < 16.0 + e.r:
				e.orbit_hit = game.time
				game.hit_enemy(e, s.damage, {"knockback": 170.0, "dir": Vector2.from_angle(a + PI / 2)})
	slot.data["pieces"] = pieces


func draw_over(ci: CanvasItem, _p: Player, slot: WeaponSlot, _s: Dictionary) -> void:
	for piece in slot.data.get("pieces", []):
		draw_piece(ci, piece[0], piece[1], slot)


func draw_piece(ci: CanvasItem, c: Vector2, _a: float, _slot: WeaponSlot) -> void:
	U.disc(ci, c, 12.0, color, Art.INK, 2.0)
