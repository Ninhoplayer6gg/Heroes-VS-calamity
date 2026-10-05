extends HeroBase
## Inspirado no Thor (mitologia nórdica): martelo que volta e o poder do trovão.


func _init() -> void:
	id = "thorvald"
	name = "Thorvald"
	title = "Filho do Trovão"
	desc = "Deus nórdico do trovão. Forte e resistente; o martelo sempre volta para a mão."
	color = Color("8d98a8")
	dark = Color("3b4250")
	start_weapon = "thunder_hammer"
	mods = {"max_hp": 25.0, "damage": 0.15, "speed": -0.05}
	ability_name = "Ira do Trovão"
	ability_desc = "Raios caem sem parar sobre os inimigos por 3,5 segundos."
	ability_icon = "bolt"
	ability_color = Color("fff27a")
	ability_cooldown = 15.0


func cast(game: Game, p: Player) -> void:
	game.add_fx(Fx.Ring.new(p.position, 160.0, Color("fff27a"), 0.4, 8.0))
	for i in 24:
		game.schedule(i * 0.15, _strike.bind(game, p))


func _strike(game: Game, p: Player) -> void:
	var target := game.random_enemy(p.position, 520.0)
	if target == null:
		return
	var radius: float = 55.0 * p.stats.area
	game.damage_area(target.pos, radius, 32.0 * game.ability_scale(), {"knockback": 80.0})
	game.add_fx(Fx.Lightning.new([target.pos + Vector2(randf_range(-40, 40), -420), target.pos], Color("fff27a"), 0.25, 4.0))
	game.add_fx(Fx.Ring.new(target.pos, radius, Color("fff27a"), 0.25, 3.0))
	Sfx.play("zap")


func draw_body(ci: CanvasItem, c: Vector2, r: float, f: float, t: float, opts: Dictionary = {}) -> void:
	var moving: bool = opts.get("moving", false)
	var cy := c - Vector2(0, bob(t, opts))
	Art.shadow(ci, c, r)
	Art.cape(ci, cy, r, f, t, Color("c0262d"), moving)
	# cabelo loiro dos lados
	for s in [-1.0, 1.0]:
		U.ellipse(ci, cy + Vector2(s * r * 0.85, r * 0.1), r * 0.3, r * 0.55, Color("f2c14e"))
	Art.body(ci, cy, r, body_color(opts))
	# capacete com asas
	var helm := PackedVector2Array()
	for i in 13:
		helm.append(cy + Vector2.from_angle(PI * 1.05 + PI * 0.9 * i / 12.0) * (r + 1.5))
	U.poly(ci, helm, Color("c9d3e0"), Art.INK, 2.0)
	for s in [-1.0, 1.0]:
		U.poly(ci, PackedVector2Array([cy + Vector2(s * r * 0.75, -r * 0.55), cy + Vector2(s * r * 1.45, -r * 1.25), cy + Vector2(s * r * 1.1, -r * 0.6), cy + Vector2(s * r * 1.35, -r * 0.85), cy + Vector2(s * r * 0.85, -r * 0.3)]), Color.WHITE, Art.INK, 1.5)
	Art.eyes(ci, cy + Vector2(0, r * 0.08), r, f)
	# discos da armadura
	for i in 2:
		U.disc(ci, cy + Vector2(-r * 0.3 + i * r * 0.6, r * 0.6), r * 0.15, Color("3b4250"), Art.INK, 1.0)
