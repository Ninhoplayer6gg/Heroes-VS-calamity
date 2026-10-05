class_name Art
## Desenho compartilhado: corpo, olhos, inimigos, chefes, projéteis e coletáveis.
## Os heróis se desenham nos próprios scripts (scripts/heroes/), usando estas peças.

const INK := Color("140c12")
const SHADOW := Color(0, 0, 0, 0.35)


static func shadow(ci: CanvasItem, c: Vector2, r: float) -> void:
	U.ellipse(ci, c + Vector2(0, r * 0.85), r * 0.95, r * 0.35, SHADOW)


## Corpo redondo com contorno grosso (estilo quadrinho) e brilho
static func body(ci: CanvasItem, c: Vector2, r: float, fill: Color, outline: Color = INK) -> void:
	U.disc(ci, c, r, fill, outline, 3.0)
	U.ellipse(ci, c + Vector2(-r * 0.3, -r * 0.38), r * 0.42, r * 0.26, Color(1, 1, 1, 0.18), -0.5)


## Olhos. opts: size, angry (bool), glow (Color), white (Color), pupil (Color)
static func eyes(ci: CanvasItem, c: Vector2, r: float, facing: float, opts: Dictionary = {}) -> void:
	var ex := c.x + facing * r * 0.22
	var gap := r * 0.3
	var er: float = opts.get("size", r * 0.19)
	for s in [-1.0, 1.0]:
		var e := Vector2(ex + s * gap, c.y)
		if opts.has("glow"):
			var g: Color = opts.glow
			U.disc(ci, e, er * 2.0, Color(g, 0.3))
			U.disc(ci, e, er * 0.85, g)
			continue
		U.ellipse(ci, e, er, er * 1.25, opts.get("white", Color.WHITE))
		U.disc(ci, e + Vector2(facing * er * 0.35, er * 0.1), er * 0.55, opts.get("pupil", INK))
		if opts.get("angry", false):
			var y1 := e.y - er * (1.9 if s > 0 else 1.2)
			var y2 := e.y - er * (1.2 if s > 0 else 1.9)
			ci.draw_line(Vector2(e.x - er * 1.1, y1), Vector2(e.x + er * 1.1, y2), INK, 2.0, true)


## Máscara/olhos brancos de herói (lentes sem pupila)
static func lenses(ci: CanvasItem, c: Vector2, r: float, facing: float, col: Color = Color.WHITE) -> void:
	var ex := c.x + facing * r * 0.2
	for s in [-1.0, 1.0]:
		var e := Vector2(ex + s * r * 0.32, c.y)
		var pts := PackedVector2Array([e + Vector2(-r * 0.22 * s, -r * 0.16), e + Vector2(r * 0.24 * s, -r * 0.2), e + Vector2(r * 0.18 * s, r * 0.14), e + Vector2(-r * 0.2 * s, r * 0.1)])
		U.poly(ci, pts, col, INK, 1.5)


## Capa que balança atrás do herói
static func cape(ci: CanvasItem, c: Vector2, r: float, facing: float, t: float, col: Color, moving: bool) -> void:
	var sway := sin(t * (12.0 if moving else 3.0)) * r * (0.25 if moving else 0.1)
	var back := -facing * r * (0.9 if moving else 0.4)
	var pts := PackedVector2Array([
		c + Vector2(-r * 0.75, -r * 0.35),
		c + Vector2(r * 0.75, -r * 0.35),
		c + Vector2(r * 0.95 + back, r * 1.2 + sway),
		c + Vector2(back * 0.6, r * 1.35 - sway),
		c + Vector2(-r * 0.95 + back, r * 1.2 + sway),
	])
	U.poly(ci, pts, col, INK, 2.5)


# ---------- Inimigos ----------

static func enemy(ci: CanvasItem, e: Enemy, t: float, player_x: float) -> void:
	var f := 1.0 if player_x >= e.pos.x else -1.0
	var r: float = e.r
	var c: Vector2 = e.pos
	var frozen: bool = e.freeze_t > 0.0
	var fill: Color = Color.WHITE if e.flash > 0.0 else e.color
	if frozen:
		fill = fill.lerp(Color("bfeaff"), 0.6)
	var dark: Color = e.def.get("dark", INK)
	var id: String = e.def.id

	if e.elite:
		U.disc(ci, c, r * 1.45 + sin(t * 6.0) * 2.0, Color(Config.C_GOLD, 0.18))

	match id:
		"slime":
			var sq := sin(e.t * 6.0) * 0.1
			U.ellipse(ci, c + Vector2(0, r * sq * 0.5), r * (1.0 + sq), r * (1.0 - sq), dark)
			U.ellipse(ci, c + Vector2(0, r * sq * 0.5), r * (1.0 + sq) - 2.5, r * (1.0 - sq) - 2.5, fill)
			U.ellipse(ci, c + Vector2(-r * 0.35, -r * 0.4), r * 0.25, r * 0.15, Color(1, 1, 1, 0.3), -0.6)
			eyes(ci, c, r, f, {"angry": true, "size": r * 0.17})
		"bat":
			var flap := sin(e.t * 22.0)
			var wing := Color.WHITE if e.flash > 0.0 else Color("5a2d7a")
			for s in [-1.0, 1.0]:
				U.poly(ci, PackedVector2Array([
					c + Vector2(s * r * 0.5, -r * 0.2), c + Vector2(s * r * 2.1, -r * (0.9 + flap * 0.8)),
					c + Vector2(s * r * 1.6, r * 0.2), c + Vector2(s * r * 1.1, -r * 0.05), c + Vector2(s * r * 0.8, r * 0.5)]), wing, INK, 1.5)
			body(ci, c, r, fill, dark)
			eyes(ci, c, r, f, {"glow": Color("ff4d4d"), "size": r * 0.16})
		"brute", "golem":
			var golem := id == "golem"
			var rect := Rect2(c - Vector2(r, r * 0.9), Vector2(r * 2.0, r * 1.85))
			var sb_pts := _round_rect(rect, r * (0.3 if golem else 0.55))
			U.poly(ci, sb_pts, fill, dark, 3.0)
			if golem:
				ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.5), c + Vector2(-r * 0.2, 0), c + Vector2(-r * 0.45, r * 0.6)]), Color("ff8a3d"), 2.5, true)
				ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.5, -r * 0.7), c + Vector2(r * 0.25, -r * 0.1)]), Color("ff8a3d"), 2.5, true)
				eyes(ci, c + Vector2(0, -r * 0.25), r, f, {"glow": Color("ff8a3d"), "size": r * 0.12})
			else:
				for s in [-1.0, 1.0]:
					U.poly(ci, PackedVector2Array([c + Vector2(s * r * 0.55, -r * 0.8), c + Vector2(s * r * 0.85, -r * 1.45), c + Vector2(s * r * 0.25, -r * 0.85)]), Config.C_BONE, INK, 1.5)
				eyes(ci, c + Vector2(0, -r * 0.2), r, f, {"angry": true, "size": r * 0.15})
				ci.draw_rect(Rect2(c + Vector2(-r * 0.4 + f * r * 0.15, r * 0.3), Vector2(r * 0.8, r * 0.18)), Color("2a1d1a"))
		"cultist":
			var pts := PackedVector2Array()
			pts.append(c + Vector2(0, -r * 1.5))
			for i in 9:
				var k := i / 8.0
				pts.append(c + Vector2(lerpf(r * 0.4, r * 1.05, k), lerpf(-r * 1.1, r, k)))
			for i in 9:
				var k := 1.0 - i / 8.0
				pts.append(c + Vector2(-lerpf(r * 0.4, r * 1.05, k), lerpf(-r * 1.1, r, k)))
			U.poly(ci, pts, fill, dark, 2.5)
			U.ellipse(ci, c + Vector2(f * r * 0.15, -r * 0.15), r * 0.5, r * 0.42, Color("12080f"))
			var glow_a := 1.0 if e.shoot_t < 0.5 else 0.6
			U.disc(ci, c + Vector2(f * r * 0.2, -r * 0.15), r * 0.18, Color(Config.C_GOLD, glow_a))
		"bomber":
			var fuse: bool = e.state == "fuse"
			var rr: float = r * ((1.0 + (0.55 - e.state_t) * 0.5) if fuse else 1.0)
			var blink := fuse and sin(e.t * 40.0) > 0.0
			body(ci, c, rr, Color.WHITE if (e.flash > 0.0 or blink) else Color("4a4f5c"), INK)
			ci.draw_rect(Rect2(c + Vector2(-rr * 0.55, -rr * 0.15), Vector2(rr * 1.1, rr * 0.4)), Color("1c1f26"))
			for s in [-1.0, 1.0]:
				U.disc(ci, c + Vector2(f * rr * 0.1 + s * rr * 0.28, rr * 0.05), rr * 0.12, Color("ff4d4d"))
			ci.draw_line(c + Vector2(0, -rr), c + Vector2(rr * 0.3, -rr * 1.45), Color("a07a50"), 3.0, true)
			U.disc(ci, c + Vector2(rr * 0.3, -rr * 1.45), 3.5 + randf() * 2.0, Config.C_GOLD if sin(e.t * 30.0) > 0.0 else Config.C_EMBER)
		"boar":
			var shake := sin(e.t * 60.0) * 2.0 if e.state == "aim" else 0.0
			var bc := c + Vector2(shake, 0)
			U.ellipse(ci, bc, r * 1.2, r * 0.95, dark)
			U.ellipse(ci, bc, r * 1.2 - 2.5, r * 0.95 - 2.5, fill)
			U.ellipse(ci, bc + Vector2(f * r * 0.85, r * 0.15), r * 0.4, r * 0.32, Color("c48b6a"))
			ci.draw_polyline(PackedVector2Array([bc + Vector2(f * r * 0.7, r * 0.4), bc + Vector2(f * r * 1.05, r * 0.38), bc + Vector2(f * r * 1.2, -r * 0.05)]), Config.C_BONE, 3.0, true)
			eyes(ci, bc + Vector2(f * r * 0.1, -r * 0.35), r, f, {"angry": true, "size": r * 0.14})
		"wraith":
			var a := 0.55 + sin(e.t * 3.0) * 0.2
			var wv := sin(e.t * 8.0) * 3.0
			var pts := PackedVector2Array()
			for i in 13:
				pts.append(c + Vector2(0, -r * 0.2) + Vector2.from_angle(PI + PI * i / 12.0) * r)
			for i in 9:
				var x := r - i * (2.0 * r) / 8.0
				pts.append(c + Vector2(x, r * (1.1 if i % 2 == 0 else 0.6) + wv))
			ci.draw_colored_polygon(pts, Color(fill, a))
			for s in [-1.0, 1.0]:
				U.ellipse(ci, c + Vector2(f * r * 0.2 + s * r * 0.32, -r * 0.25), r * 0.16, r * 0.26, Color("0d1a26"))
		_:
			body(ci, c, r, fill, dark)
			eyes(ci, c, r, f, {"angry": true})

	_status(ci, e, t)

	if e.elite:
		ci.draw_circle(c, r * 1.25, Config.C_GOLD, false, 2.5, true)
		Icons.draw(ci, "crown", c + Vector2(0, -r * 1.6), r * 0.5, Config.C_GOLD)
		var w := r * 2.0
		ci.draw_rect(Rect2(c + Vector2(-w / 2, r * 1.35), Vector2(w, 4)), Color(0, 0, 0, 0.6))
		ci.draw_rect(Rect2(c + Vector2(-w / 2, r * 1.35), Vector2(w * clampf(e.hp / e.max_hp, 0, 1), 4)), Config.C_GOLD)


## Indicadores de congelado, preso na teia e lento
static func _status(ci: CanvasItem, e: Enemy, t: float) -> void:
	var c: Vector2 = e.pos
	var r: float = e.r
	if e.freeze_t > 0.0:
		U.disc(ci, c, r * 1.1, Color(0.75, 0.92, 1.0, 0.35), Color(0.85, 0.97, 1.0, 0.9), 2.0)
		for i in 3:
			var a := TAU * i / 3.0 + 0.4
			U.poly(ci, PackedVector2Array([c + Vector2.from_angle(a) * r * 0.6, c + Vector2.from_angle(a + 0.25) * r * 1.3, c + Vector2.from_angle(a + 0.4) * r * 0.7]), Color(1, 1, 1, 0.7))
	elif e.root_t > 0.0:
		for i in 4:
			var a := PI * i / 4.0
			ci.draw_line(c - Vector2.from_angle(a) * r * 1.2, c + Vector2.from_angle(a) * r * 1.2, Color(1, 1, 1, 0.75), 1.5, true)
		ci.draw_circle(c, r * 0.8, Color(1, 1, 1, 0.6), false, 1.5, true)
	elif e.slow_t > 0.0:
		ci.draw_arc(c, r * 1.15, t * 4.0, t * 4.0 + PI * 1.2, 12, Color(0.6, 0.85, 1.0, 0.7), 2.0, true)


static func _round_rect(rect: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [rect.position + Vector2(rect.size.x - rad, rad), rect.position + Vector2(rect.size.x - rad, rect.size.y - rad), rect.position + Vector2(rad, rect.size.y - rad), rect.position + Vector2(rad, rad)]
	var start := [-PI / 2, 0.0, PI / 2, PI]
	for k in 4:
		for i in 5:
			pts.append(corners[k] + Vector2.from_angle(start[k] + PI / 2 * i / 4.0) * rad)
	return pts


static func boss(ci: CanvasItem, b: Boss, t: float, player_x: float) -> void:
	var r: float = b.r
	var c: Vector2 = b.pos
	var f := 1.0 if player_x >= c.x else -1.0
	var fill: Color = Color.WHITE if b.flash > 0.0 else b.color
	var final: bool = b.def.id == "calamity"

	shadow(ci, c, r)
	U.disc(ci, c, r * (1.4 + sin(t * 4.0) * 0.08), Color(1.0, 0.3, 0.15, 0.16) if final else Color(0.7, 0.23, 0.28, 0.16))

	var spikes := 12 if final else 7
	for i in spikes:
		var a := (TAU * i / spikes + t * 0.5) if final else (PI + PI * i / (spikes - 1))
		var length := r * 1.5 + sin(t * 5.0 + i) * 3.0
		U.poly(ci, PackedVector2Array([c + Vector2.from_angle(a - 0.18) * r * 0.9, c + Vector2.from_angle(a) * length, c + Vector2.from_angle(a + 0.18) * r * 0.9]), Color("2a0f12") if final else Color("3a1420"))

	body(ci, c, r, fill, Color("1a0a0e"))
	var charging: bool = b.state == "aim"
	U.ellipse(ci, c + Vector2(f * r * 0.1, -r * 0.05), r * 0.5, r * 0.36, Color("12060a"))
	U.ellipse(ci, c + Vector2(f * r * 0.22, -r * 0.05), r * 0.2, r * 0.3, Color.WHITE if charging else Config.C_GOLD)
	U.ellipse(ci, c + Vector2(f * r * 0.26, -r * 0.05), r * 0.06, r * 0.24, Color("12060a"))
	if final:
		for s in [-1.0, 1.0]:
			U.disc(ci, c + Vector2(s * r * 0.55, -r * 0.5), r * 0.1, Config.C_GOLD)
			U.disc(ci, c + Vector2(s * r * 0.6, r * 0.4), r * 0.08, Config.C_GOLD)
	if b.rage:
		ci.draw_circle(c, r * 1.12 + sin(t * 20.0) * 2.0, Color(1, 0.25, 0.15, 0.6), false, 3.0, true)
	_status(ci, b, t)


# ---------- Projéteis ----------

static func projectile(ci: CanvasItem, p: Projectile) -> void:
	var a: float = p.vel.angle()
	var c: Vector2 = p.pos
	match p.kind:
		"repulsor":
			U.disc(ci, c, p.r * 2.2, Color(0.6, 0.85, 1.0, 0.25))
			U.disc(ci, c, p.r, Color("bfe9ff"))
			U.disc(ci, c, p.r * 0.5, Color.WHITE)
		"grenade":
			U.disc(ci, c, p.r * 2.0, Color(0.7, 0.4, 1.0, 0.25))
			U.disc(ci, c, p.r, Color("b67cff"), INK, 2.0)
			U.disc(ci, c + Vector2(-2, -2), p.r * 0.4, Color(1, 1, 1, 0.7))
		"missile":
			ci.draw_set_transform(c, a, Vector2.ONE)
			U.poly(ci, PackedVector2Array([Vector2(10, 0), Vector2(2, -4), Vector2(-8, -4), Vector2(-8, 4), Vector2(2, 4)]), Color("d9dde6"), INK, 1.5)
			U.poly(ci, PackedVector2Array([Vector2(-8, -4), Vector2(-14, 0), Vector2(-8, 4)]), Config.C_EMBER)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"hammer":
			ci.draw_set_transform(c, p.rot, Vector2.ONE)
			ci.draw_line(Vector2(0, 2), Vector2(0, 18), Color("7a5230"), 4.0, true)
			ci.draw_rect(Rect2(Vector2(-13, -12), Vector2(26, 16)), Color("aeb6c4"))
			ci.draw_rect(Rect2(Vector2(-13, -12), Vector2(26, 16)), INK, false, 2.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			U.disc(ci, c, p.r * 1.6, Color(0.6, 0.9, 1.0, 0.18))
		"batarang":
			ci.draw_set_transform(c, p.rot, Vector2.ONE)
			var s: float = p.r * 1.4
			U.poly(ci, PackedVector2Array([Vector2(-s, -s * 0.25), Vector2(-s * 0.55, -s * 0.05), Vector2(-s * 0.3, -s * 0.35), Vector2(0, 0), Vector2(s * 0.3, -s * 0.35), Vector2(s * 0.55, -s * 0.05), Vector2(s, -s * 0.25), Vector2(s * 0.6, s * 0.35), Vector2(0, s * 0.5), Vector2(-s * 0.6, s * 0.35)]), Color("3a3d47"), Color("c9cfd8"), 1.5)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"web":
			U.disc(ci, c, p.r, Color(1, 1, 1, 0.9))
			for i in 4:
				ci.draw_line(c, c + Vector2.from_angle(p.rot + TAU * i / 4.0) * p.r * 1.7, Color(1, 1, 1, 0.8), 1.5, true)
		"fist":
			ci.draw_set_transform(c, a, Vector2.ONE)
			var s2: float = p.r
			U.disc(ci, Vector2.ZERO, s2 * 1.25, Color(0.2, 1.0, 0.5, 0.18))
			U.poly(ci, PackedVector2Array([Vector2(-s2 * 0.6, -s2 * 0.7), Vector2(s2 * 0.55, -s2 * 0.75), Vector2(s2 * 0.95, -s2 * 0.2), Vector2(s2 * 0.95, s2 * 0.45), Vector2(s2 * 0.4, s2 * 0.8), Vector2(-s2 * 0.6, s2 * 0.6)]), Color(0.3, 1.0, 0.55, 0.85), Color("b8ffd0"), 3.0)
			for k in 3:
				ci.draw_line(Vector2(s2 * 0.2, -s2 * 0.45 + k * s2 * 0.38), Vector2(s2 * 0.9, -s2 * 0.4 + k * s2 * 0.38), Color("0b5a2a"), 2.5, true)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"drone_bolt":
			ci.draw_line(c - p.vel.normalized() * 12.0, c, Color("ff5d5d"), 3.0, true)
			U.disc(ci, c, 3.0, Color("ffd0d0"))
		"shard":
			ci.draw_line(c - p.vel.normalized() * 14.0, c, Color(p.color, 0.6), 4.0, true)
			U.disc(ci, c, p.r, p.color)
		_:
			U.disc(ci, c, p.r, p.color)


static func enemy_bullet(ci: CanvasItem, b: Projectile) -> void:
	U.disc(ci, b.pos, b.r * 1.8, Color(b.color, 0.3))
	U.disc(ci, b.pos, b.r, b.color)
	U.disc(ci, b.pos, b.r * 0.45, Color("fff0f4"))


# ---------- Coletáveis ----------

static func pickup(ci: CanvasItem, p: Pickup, t: float) -> void:
	var c: Vector2 = p.pos + Vector2(0, sin(t * 4.0 + p.t) * 2.0)
	match p.kind:
		"gem":
			var s := 8.0 if p.value >= 8 else (6.5 if p.value >= 3 else 5.0)
			var col := Color("c084ff") if p.value >= 8 else (Color("5aa9ff") if p.value >= 3 else Color("5fd3a8"))
			Icons.draw(ci, "gem", c, s * 1.3, col)
		"heart":
			Icons.draw(ci, "heart", c, 9.0, Config.C_HP)
		"chest":
			U.disc(ci, c, 26.0 + sin(t * 5.0) * 3.0, Color(Config.C_GOLD, 0.25))
			ci.draw_rect(Rect2(c - Vector2(15, 10), Vector2(30, 20)), Color("8a5a2b"))
			ci.draw_rect(Rect2(c - Vector2(15, 10), Vector2(30, 20)), Color("3d2410"), false, 2.0)
			ci.draw_rect(Rect2(c + Vector2(-15, -3), Vector2(30, 4)), Config.C_GOLD)
			ci.draw_rect(Rect2(c + Vector2(-3, -5), Vector2(6, 8)), Config.C_GOLD)
