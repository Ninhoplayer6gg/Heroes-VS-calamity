extends HeroBase
## Inspirado no Flash: o mais rápido de todos, deixa rastro elétrico e desacelera o tempo.


func _init() -> void:
	id = "scarlet_bolt"
	name = "Relâmpago Escarlate"
	title = "O Mais Rápido Vivo"
	desc = "Corre tão rápido que deixa um rastro de raios. Frágil, mas quase impossível de pegar."
	color = Color("d41e2b")
	dark = Color("5c0a10")
	start_weapon = "speed_trail"
	mods = {"speed": 0.35, "dodge": 0.08, "max_hp": -20.0}
	ability_name = "Câmera Lenta"
	ability_desc = "Por 4s o mundo quase para: inimigos e projéteis a 25% da velocidade, e você ataca 40% mais rápido."
	ability_icon = "clock"
	ability_color = Color("ffd23f")
	ability_cooldown = 18.0


func cast(game: Game, p: Player) -> void:
	game.time_slow = 4.0
	p.add_buff("speedforce", {"attack_speed": 0.4}, 4.0)
	game.add_fx(Fx.Ring.new(p.position, 220.0, Color("ffd23f"), 0.5, 8.0))


func draw_body(ci: CanvasItem, c: Vector2, r: float, f: float, t: float, opts: Dictionary = {}) -> void:
	var cy := c - Vector2(0, bob(t, opts))
	Art.shadow(ci, c, r)
	if opts.get("moving", false):
		for i in 3:
			var y := (i - 1) * r * 0.45
			ci.draw_line(cy + Vector2(-f * r * 1.2, y), cy + Vector2(-f * r * (2.0 + i * 0.3), y), Color(1.0, 0.82, 0.25, 0.6), 2.5, true)
	# asas-raio nas orelhas
	for s in [-1.0, 1.0]:
		var o := cy + Vector2(s * r * 0.95, -r * 0.2)
		U.poly(ci, PackedVector2Array([o, o + Vector2(s * r * 0.55, -r * 0.35), o + Vector2(s * r * 0.3, -r * 0.1), o + Vector2(s * r * 0.6, -r * 0.05), o + Vector2(0, r * 0.2)]), Color("ffd23f"), Art.INK, 1.5)
	Art.body(ci, cy, r, body_color(opts))
	# rosto à mostra
	U.ellipse(ci, cy + Vector2(f * r * 0.12, -r * 0.08), r * 0.58, r * 0.36, Color("f1c9a5"))
	Art.eyes(ci, cy + Vector2(0, -r * 0.12), r, f, {"size": r * 0.15})
	# emblema
	var e := cy + Vector2(0, r * 0.58)
	U.disc(ci, e, r * 0.27, Color.WHITE, Art.INK, 1.5)
	Icons.draw(ci, "bolt", e, r * 0.22, Color("ffd23f"))
