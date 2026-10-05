extends HeroBase
## Inspirado no Homem de Ferro: armadura tecnológica, repulsores e mísseis.


func _init() -> void:
	id = "crimson_armor"
	name = "Armadura Rubra"
	title = "Gênio Blindado"
	desc = "Inventor bilionário numa armadura de alta tecnologia. Muita armadura, ataques rápidos."
	color = Color("c1272d")
	dark = Color("5c0f13")
	start_weapon = "repulsor"
	mods = {"armor": 5.0, "attack_speed": 0.1, "speed": -0.06}
	ability_name = "Salva de Micromísseis"
	ability_desc = "Dispara uma salva de mísseis teleguiados que explodem ao acertar."
	ability_icon = "rocket"
	ability_color = Color("ffb35c")
	ability_cooldown = 14.0


func cast(game: Game, p: Player) -> void:
	var n := 12 + int(p.stats.projectiles) * 2
	for i in n:
		game.schedule(i * 0.06, _launch.bind(game, p))


func _launch(game: Game, p: Player) -> void:
	var a := -PI / 2 + randf_range(-1.2, 1.2)
	game.add_projectile({"kind": "missile", "pos": p.position + Vector2(0, -10), "vel": Vector2.from_angle(a) * 420.0, "r": 7.0,
		"damage": 35.0 * game.ability_scale(), "explode": 55.0 * p.stats.area, "homing": 6.0,
		"target": game.random_enemy(p.position, 600.0), "life": 3.0, "color": Color("ffb35c")})
	Sfx.play("shoot")


func draw_body(ci: CanvasItem, c: Vector2, r: float, f: float, t: float, opts: Dictionary = {}) -> void:
	var cy := c - Vector2(0, bob(t, opts))
	Art.shadow(ci, c, r)
	Art.body(ci, cy, r, body_color(opts))
	# máscara dourada
	var fx := f * r * 0.12
	var mask := PackedVector2Array([cy + Vector2(fx - r * 0.6, -r * 0.55), cy + Vector2(fx + r * 0.6, -r * 0.55), cy + Vector2(fx + r * 0.62, r * 0.05),
		cy + Vector2(fx + r * 0.3, r * 0.32), cy + Vector2(fx - r * 0.3, r * 0.32), cy + Vector2(fx - r * 0.62, r * 0.05)])
	U.poly(ci, mask, Color("f2c14e"), Art.INK, 2.0)
	for s in [-1.0, 1.0]:
		var e := cy + Vector2(fx + s * r * 0.3, -r * 0.18)
		ci.draw_line(e - Vector2(r * 0.17, 0), e + Vector2(r * 0.17, -r * 0.03 * s), Color("d8f6ff"), 3.0, true)
	ci.draw_line(cy + Vector2(fx - r * 0.2, r * 0.15), cy + Vector2(fx + r * 0.2, r * 0.15), Art.INK, 1.5, true)
	# reator no peito
	var core := cy + Vector2(0, r * 0.62)
	U.disc(ci, core, r * 0.3, Color(0.55, 0.9, 1.0, 0.35))
	U.disc(ci, core, r * 0.16, Color("d8f6ff"), Art.INK, 1.5)
