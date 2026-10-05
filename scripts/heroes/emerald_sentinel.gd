extends HeroBase
## Inspirado no Lanterna Verde: anel que cria construtos com a força de vontade.


func _init() -> void:
	id = "emerald_sentinel"
	name = "Sentinela Esmeralda"
	title = "A Vontade Feita Luz"
	desc = "Um anel transforma força de vontade em construtos de energia verde."
	color = Color("2ecc71")
	dark = Color("0f5a32")
	start_weapon = "ring_constructs"
	mods = {"area": 0.2, "cooldown": -0.2, "max_hp": -10.0}
	ability_name = "Punho Esmeralda"
	ability_desc = "Lança um punho gigante de energia contra o inimigo mais próximo, arremessando tudo no caminho."
	ability_icon = "fist"
	ability_color = Color("5dffa0")
	ability_cooldown = 9.0


func cast(game: Game, p: Player) -> void:
	var size: float = 42.0 * p.stats.area
	game.add_projectile({"kind": "fist", "pos": p.position, "vel": aim_dir(game, p, 700.0) * 1100.0, "r": size, "damage": 70.0 * game.ability_scale(),
		"pierce": 999, "knockback": 650.0, "life": 0.7, "color": Color("5dffa0")})
	game.add_fx(Fx.Ring.new(p.position, 90.0, Color("5dffa0"), 0.3, 6.0))
	game.shake(4.0)


func draw_body(ci: CanvasItem, c: Vector2, r: float, f: float, t: float, opts: Dictionary = {}) -> void:
	var cy := c - Vector2(0, bob(t, opts))
	Art.shadow(ci, c, r)
	U.disc(ci, cy, r * 1.35 + sin(t * 3.0) * 1.5, Color(0.36, 1.0, 0.63, 0.13))
	Art.body(ci, cy, r, body_color(opts))
	# parte de baixo escura do uniforme
	var lower := PackedVector2Array()
	for i in 13:
		lower.append(cy + Vector2.from_angle(PI * 0.08 + PI * 0.84 * i / 12.0) * (r - 1.5))
	U.poly(ci, lower, Color("15211b"))
	# máscara e olhos brancos
	U.ellipse(ci, cy + Vector2(f * r * 0.2, -r * 0.12), r * 0.7, r * 0.28, Color("0f5a32"))
	Art.lenses(ci, cy + Vector2(0, -r * 0.12), r, f)
	# emblema de lanterna
	var e := cy + Vector2(0, r * 0.5)
	U.disc(ci, e, r * 0.24, Color.WHITE, Art.INK, 1.5)
	ci.draw_circle(e, r * 0.13, Color("2ecc71"), false, 2.5, true)
