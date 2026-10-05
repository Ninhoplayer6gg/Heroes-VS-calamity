extends HeroBase
## Inspirada na Mulher-Maravilha: guerreira com laço dourado e braceletes.


func _init() -> void:
	id = "amazon"
	name = "Amazona Imortal"
	title = "Princesa Guerreira"
	desc = "Guerreira lendária e resistente, com laço dourado e braceletes que refletem projéteis."
	color = Color("c8102e")
	dark = Color("5c0714")
	start_weapon = "golden_lasso"
	mods = {"max_hp": 20.0, "armor": 2.0, "crit": 0.08}
	ability_name = "Braceletes Refletores"
	ability_desc = "Por 4s reflete os projéteis inimigos e ganha +8 de armadura. Solta uma onda de choque."
	ability_icon = "shield"
	ability_color = Color("f2c14e")
	ability_cooldown = 12.0


func cast(game: Game, p: Player) -> void:
	p.reflect = 4.0
	p.add_buff("bracers", {"armor": 8.0}, 4.0)
	var radius: float = 160.0 * p.stats.area
	game.damage_area(p.position, radius, 30.0 * game.ability_scale(), {"knockback": 420.0})
	game.add_fx(Fx.Ring.new(p.position, radius, Color("f2c14e"), 0.4, 8.0))
	game.shake(5.0)


func draw_body(ci: CanvasItem, c: Vector2, r: float, f: float, t: float, opts: Dictionary = {}) -> void:
	var cy := c - Vector2(0, bob(t, opts))
	Art.shadow(ci, c, r)
	# cabelo longo atrás
	U.ellipse(ci, cy + Vector2(-f * r * 0.15, r * 0.2), r * 1.05, r * 1.2, Color("1a1216"))
	Art.body(ci, cy, r, body_color(opts))
	# saia azul com estrelas
	var skirt := PackedVector2Array()
	for i in 13:
		skirt.append(cy + Vector2.from_angle(PI * 0.12 + PI * 0.76 * i / 12.0) * (r - 1.5))
	U.poly(ci, skirt, Color("1d3d8f"))
	for s in [-1.0, 1.0]:
		Icons.draw(ci, "star", cy + Vector2(s * r * 0.35, r * 0.72), r * 0.13, Color.WHITE)
	# águia dourada no peito
	ci.draw_polyline(PackedVector2Array([cy + Vector2(-r * 0.5, r * 0.25), cy + Vector2(-r * 0.25, r * 0.45), cy + Vector2(0, r * 0.28), cy + Vector2(r * 0.25, r * 0.45), cy + Vector2(r * 0.5, r * 0.25)]), Color("f2c14e"), 3.0, true)
	# franja e tiara
	var bangs := PackedVector2Array()
	for i in 13:
		bangs.append(cy + Vector2.from_angle(PI * 1.05 + PI * 0.9 * i / 12.0) * (r + 1.0))
	U.poly(ci, bangs, Color("1a1216"))
	ci.draw_line(cy + Vector2(-r * 0.6, -r * 0.5), cy + Vector2(r * 0.6, -r * 0.5), Color("f2c14e"), 3.0, true)
	Icons.draw(ci, "star", cy + Vector2(0, -r * 0.55), r * 0.2, Color("d42a2a"))
	Art.eyes(ci, cy + Vector2(0, -r * 0.05), r, f)
