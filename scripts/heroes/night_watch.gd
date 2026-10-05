extends HeroBase
## Inspirado no Batman: sem superpoderes, mas com treino, dinheiro e equipamentos.


func _init() -> void:
	id = "night_watch"
	name = "Vigia Noturno"
	title = "O Detetive das Sombras"
	desc = "Sem superpoderes: treino, equipamentos e fortuna. Críticos, esquiva e mais ouro."
	color = Color("4a4f5a")
	dark = Color("15161b")
	start_weapon = "batarang"
	mods = {"crit": 0.1, "dodge": 0.06, "gold_gain": 0.25, "luck": 10.0, "max_hp": -5.0}
	ability_name = "Bomba de Fumaça"
	ability_desc = "Some numa nuvem de fumaça por 3s: os inimigos perdem você de vista e quem fica na fumaça sofre dano e lentidão."
	ability_icon = "cloud"
	ability_color = Color("9aa6b8")
	ability_cooldown = 12.0


func cast(game: Game, p: Player) -> void:
	var center := p.position
	var radius: float = 170.0 * p.stats.area
	p.stealth = 3.0
	p.invuln = maxf(p.invuln, 0.5)
	game.add_fx(Fx.Smoke.new(center, radius, 3.0))
	for i in 8:
		game.schedule(i * 0.4, game.damage_area.bind(center, radius, 12.0 * game.ability_scale(), {"slow": 0.4, "slow_time": 0.6}))


func draw_body(ci: CanvasItem, c: Vector2, r: float, f: float, t: float, opts: Dictionary = {}) -> void:
	var moving: bool = opts.get("moving", false)
	var cy := c - Vector2(0, bob(t, opts))
	Art.shadow(ci, c, r)
	Art.cape(ci, cy, r, f, t, Color("1e1f26"), moving)
	Art.body(ci, cy, r, body_color(opts))
	# capuz com orelhas
	var cowl := PackedVector2Array()
	for i in 13:
		cowl.append(cy + Vector2.from_angle(PI * 0.98 + PI * 1.04 * i / 12.0) * (r + 1.0))
	cowl.append(cy + Vector2(r * 0.45, r * 0.15))
	cowl.append(cy + Vector2(-r * 0.45, r * 0.15))
	U.poly(ci, cowl, Color("1e1f26"))
	for s in [-1.0, 1.0]:
		U.poly(ci, PackedVector2Array([cy + Vector2(s * r * 0.35, -r * 0.85), cy + Vector2(s * r * 0.55, -r * 1.45), cy + Vector2(s * r * 0.7, -r * 0.7)]), Color("1e1f26"), Art.INK, 1.5)
	# queixo
	U.ellipse(ci, cy + Vector2(f * r * 0.1, r * 0.3), r * 0.4, r * 0.2, Color("f1c9a5"))
	Art.lenses(ci, cy + Vector2(0, -r * 0.22), r * 0.9, f)
	# cinto de utilidades
	ci.draw_line(cy + Vector2(-r * 0.85, r * 0.62), cy + Vector2(r * 0.85, r * 0.62), Color("f2c14e"), 3.5, true)
