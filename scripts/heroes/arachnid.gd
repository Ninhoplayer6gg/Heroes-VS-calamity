extends HeroBase
## Inspirado no Homem-Aranha: ágil, sentido de perigo e teias que prendem.


func _init() -> void:
	id = "arachnid"
	name = "Aracnídeo"
	title = "O Amigo da Vizinhança"
	desc = "Ágil e esquivo, sente o perigo antes dele chegar e prende os inimigos em teias."
	color = Color("d42a2a")
	dark = Color("5c0f13")
	start_weapon = "web_shooter"
	mods = {"speed": 0.15, "dodge": 0.1, "attack_speed": 0.1, "max_hp": -15.0}
	ability_name = "Rede Gigante"
	ability_desc = "Lança uma teia enorme que prende os inimigos no lugar por 3 segundos."
	ability_icon = "web"
	ability_color = Color.WHITE
	ability_cooldown = 13.0


func cast(game: Game, p: Player) -> void:
	var t := game.nearest_enemy(p.position, 450.0)
	var center := t.pos if t else p.position + p.dir * 200.0
	var radius: float = 160.0 * p.stats.area
	game.add_fx(Fx.Web.new(center, radius, 3.5))
	game.damage_area(center, radius, 25.0 * game.ability_scale(), {"root": 3.0})
	game.add_fx(Fx.Lightning.new([p.position, center], Color.WHITE, 0.2, 2.0))
	Sfx.play("web")


func draw_body(ci: CanvasItem, c: Vector2, r: float, f: float, t: float, opts: Dictionary = {}) -> void:
	var cy := c - Vector2(0, bob(t, opts))
	Art.shadow(ci, c, r)
	Art.body(ci, cy, r, body_color(opts))
	# laterais azuis
	for s in [-1.0, 1.0]:
		var side := PackedVector2Array()
		for i in 7:
			side.append(cy + Vector2.from_angle((0.15 if s > 0 else PI - 0.15) + s * 0.75 * i / 6.0) * (r - 1.5))
		side.append(cy + Vector2(s * r * 0.45, r * 0.5))
		U.poly(ci, side, Color("1f4fbf"))
	# teia no rosto
	var web := Color(0.08, 0.04, 0.06, 0.55)
	var hub := cy + Vector2(f * r * 0.15, -r * 0.1)
	for i in 8:
		ci.draw_line(hub, cy + Vector2.from_angle(TAU * i / 8.0) * r * 0.95, web, 1.0, true)
	for ring in [0.4, 0.75]:
		ci.draw_arc(hub, r * ring, 0, TAU, 16, web, 1.0, true)
	# olhos grandes
	var ex := cy.x + f * r * 0.2
	for s in [-1.0, 1.0]:
		var e := Vector2(ex + s * r * 0.36, cy.y - r * 0.15)
		U.poly(ci, PackedVector2Array([e + Vector2(-r * 0.25 * s, -r * 0.25), e + Vector2(r * 0.28 * s, -r * 0.1), e + Vector2(r * 0.15 * s, r * 0.22), e + Vector2(-r * 0.22 * s, r * 0.12)]), Color.WHITE, Art.INK, 2.5)
	# aranha no peito
	U.disc(ci, cy + Vector2(0, r * 0.55), r * 0.12, Art.INK)
	for s in [-1.0, 1.0]:
		ci.draw_line(cy + Vector2(0, r * 0.55), cy + Vector2(s * r * 0.3, r * 0.4), Art.INK, 1.5, true)
		ci.draw_line(cy + Vector2(0, r * 0.55), cy + Vector2(s * r * 0.3, r * 0.72), Art.INK, 1.5, true)
