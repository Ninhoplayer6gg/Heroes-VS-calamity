extends HeroBase
## Inspirado no Superman: força, resistência, visão térmica e sopro congelante.


func _init() -> void:
	id = "solar_titan"
	name = "Titã Solar"
	title = "Esperança Vinda das Estrelas"
	desc = "Alienígena movido pela luz do sol. Muito resistente, com visão térmica e sopro congelante."
	color = Color("2f5fd0")
	dark = Color("142a66")
	start_weapon = "heat_vision"
	mods = {"max_hp": 40.0, "armor": 3.0, "regen": 0.5}
	ability_name = "Sopro Congelante"
	ability_desc = "Um sopro gélido em cone na direção do inimigo mais próximo congela todos por 2,5s."
	ability_icon = "snow"
	ability_color = Color("bfeaff")
	ability_cooldown = 14.0


func cast(game: Game, p: Player) -> void:
	var reach: float = 320.0 * p.stats.area
	var a := aim_dir(game, p, reach * 1.3).angle()
	game.cone_damage(p.position, reach, a, 1.3, 30.0 * game.ability_scale(), {"freeze": 2.5, "knockback": 120.0})
	game.add_fx(Fx.Cone.new(p.position, a, reach, 1.3, Color("bfeaff")))
	Sfx.play("freeze")


func draw_body(ci: CanvasItem, c: Vector2, r: float, f: float, t: float, opts: Dictionary = {}) -> void:
	var moving: bool = opts.get("moving", false)
	var cy := c - Vector2(0, bob(t, opts))
	Art.shadow(ci, c, r)
	Art.cape(ci, cy, r, f, t, Color("d42a2a"), moving)
	Art.body(ci, cy, r, body_color(opts))
	# cabelo com o cacho na testa
	var hair := PackedVector2Array()
	for i in 13:
		hair.append(cy + Vector2.from_angle(PI * 1.02 + PI * 0.96 * i / 12.0) * (r + 1.0))
	hair.append(cy + Vector2(r * 0.6, -r * 0.45))
	hair.append(cy + Vector2(-r * 0.6, -r * 0.45))
	U.poly(ci, hair, Color("15131c"))
	ci.draw_arc(cy + Vector2(f * r * 0.15, -r * 0.42), r * 0.16, PI * 0.2, PI * 1.6, 8, Color("15131c"), 2.5, true)
	Art.eyes(ci, cy + Vector2(0, -r * 0.05), r, f)
	# emblema: losango dourado com sol vermelho
	var e := cy + Vector2(0, r * 0.52)
	U.poly(ci, PackedVector2Array([e + Vector2(0, -r * 0.3), e + Vector2(r * 0.36, 0), e + Vector2(0, r * 0.3), e + Vector2(-r * 0.36, 0)]), Config.C_GOLD, Color("d42a2a"), 2.0)
	U.disc(ci, e, r * 0.1, Color("d42a2a"))
