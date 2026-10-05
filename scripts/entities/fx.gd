class_name Fx
## Efeitos visuais. Cada efeito tem update(dt) -> bool (false = terminou) e draw(ci).
## Efeitos com under = true são desenhados no chão, abaixo dos personagens.

const FONT_COMIC := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/BarlowSemiCondensed-Bold.ttf")


class Base extends RefCounted:
	var under := false
	var t := 0.0
	var dur := 0.4

	func update(dt: float) -> bool:
		t += dt
		return t < dur

	func draw(_ci: CanvasItem) -> void:
		pass


class Particle extends RefCounted:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var color: Color
	var size: float


class FloatText extends Base:
	var pos: Vector2
	var text: String
	var color: Color
	var size: int
	var comic := false
	var vy := -70.0

	func _init(p: Vector2, txt: String, col: Color, sz: int, is_comic: bool = false) -> void:
		pos = p + Vector2(randf_range(-8, 8), 0)
		text = txt
		color = col
		size = sz
		comic = is_comic
		dur = 0.9 if comic else 0.75

	func update(dt: float) -> bool:
		t += dt
		pos.y += vy * dt
		vy *= exp(-dt * 3.0)
		return t < dur

	func draw(ci: CanvasItem) -> void:
		var a := clampf((dur - t) / 0.3, 0.0, 1.0)
		var font: Font = Fx.FONT_COMIC if comic else Fx.FONT_BOLD
		var fs := size
		if comic:
			fs = int(size * (1.0 + maxf(0.0, 0.15 - t) * 3.0))
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p := pos - Vector2(w / 2.0, -fs * 0.35)
		ci.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5 if comic else 4, Color(0.06, 0.03, 0.05, a))
		ci.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color, a))


class Ring extends Base:
	var pos: Vector2
	var radius: float
	var color: Color
	var width: float

	func _init(p: Vector2, r: float, col: Color, d: float = 0.4, w: float = 4.0) -> void:
		pos = p
		radius = r
		color = col
		dur = d
		width = w

	func draw(ci: CanvasItem) -> void:
		var k := t / dur
		ci.draw_circle(pos, radius * (0.3 + 0.7 * sqrt(k)), Color(color, 1.0 - k), false, width * (1.0 - k) + 1.0, true)


class Explosion extends Base:
	var pos: Vector2
	var radius: float
	var color: Color

	func _init(p: Vector2, r: float, col: Color) -> void:
		pos = p
		radius = r
		color = col
		dur = 0.35

	func draw(ci: CanvasItem) -> void:
		var k := t / dur
		ci.draw_circle(pos, radius * (0.5 + 0.5 * k), Color(color, (1.0 - k) * 0.55), true, -1.0, true)
		ci.draw_circle(pos, radius * 0.45 * (1.0 - k), Color(1.0, 0.95, 0.77, (1.0 - k) * 0.9), true, -1.0, true)


## Golpe em arco que acompanha o jogador (espada)
class Slash extends Base:
	var follow: Node2D
	var angle: float
	var radius: float
	var arc: float
	var color: Color

	func _init(f: Node2D, a: float, r: float, ar: float, col: Color) -> void:
		follow = f
		angle = a
		radius = r
		arc = ar
		color = col
		dur = 0.18

	func draw(ci: CanvasItem) -> void:
		var k := t / dur
		var c := follow.position
		var a0 := angle - arc / 2.0
		var sweep := arc * minf(1.0, k * 2.2)
		var pts := PackedVector2Array()
		var n := 14
		for i in n + 1:
			pts.append(c + Vector2.from_angle(a0 + sweep * i / n) * radius)
		for i in n + 1:
			pts.append(c + Vector2.from_angle(a0 + sweep * (n - i) / n) * radius * 0.55)
		if sweep > 0.05:
			ci.draw_colored_polygon(pts, Color(color, (1.0 - k * 0.8) * 0.45))
			ci.draw_arc(c, radius, a0, a0 + sweep, 14, Color(1, 1, 1, 1.0 - k * 0.8), 3.0, true)


## Laço: corda dourada que varre um arco
class Lasso extends Base:
	var follow: Node2D
	var angle: float
	var radius: float
	var arc: float

	func _init(f: Node2D, a: float, r: float, ar: float) -> void:
		follow = f
		angle = a
		radius = r
		arc = ar
		dur = 0.25

	func draw(ci: CanvasItem) -> void:
		var k := t / dur
		var c := follow.position
		var a := angle - arc / 2.0 + arc * minf(1.0, k * 1.6)
		var tip := c + Vector2.from_angle(a) * radius
		var mid := c + Vector2.from_angle(a - 0.25) * radius * 0.55
		var pts := PackedVector2Array()
		for i in 13:
			var s := i / 12.0
			pts.append(c.lerp(mid, s).lerp(mid.lerp(tip, s), s))
		var col := Color(Config.C_GOLD, 1.0 - k * 0.7)
		ci.draw_polyline(pts, Color(1.0, 0.85, 0.3, (1.0 - k) * 0.35), 9.0, true)
		ci.draw_polyline(pts, col, 3.5, true)
		ci.draw_circle(tip, 14.0, col, false, 3.0, true)


class Beam extends Base:
	var from: Vector2
	var to: Vector2
	var color: Color
	var width: float

	func _init(a: Vector2, b: Vector2, col: Color, w: float = 4.0, d: float = 0.15) -> void:
		from = a
		to = b
		color = col
		width = w
		dur = d

	func draw(ci: CanvasItem) -> void:
		var k := t / dur
		ci.draw_line(from, to, Color(color, (1.0 - k) * 0.35), width * 3.0, true)
		ci.draw_line(from, to, Color(color, 1.0 - k), width, true)
		ci.draw_line(from, to, Color(1, 1, 1, 1.0 - k), width * 0.35, true)


class Lightning extends Base:
	var path := PackedVector2Array()
	var color: Color
	var width: float

	func _init(points: Array, col: Color, d: float = 0.2, w: float = 3.0) -> void:
		color = col
		dur = d
		width = w
		for i in points.size() - 1:
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var segs := maxi(2, int(a.distance_to(b) / 22.0))
			for s in segs:
				var j := 0.0 if s == 0 else 12.0
				path.append(a.lerp(b, float(s) / segs) + Vector2(randf_range(-j, j), randf_range(-j, j)))
		path.append(points[points.size() - 1])

	func draw(ci: CanvasItem) -> void:
		var k := t / dur
		ci.draw_polyline(path, Color(color, (1.0 - k) * 0.4), width * 3.0, true)
		ci.draw_polyline(path, Color(1, 1, 1, 1.0 - k), width, true)


class Afterimage extends Base:
	var pos: Vector2
	var hero
	var facing: float

	func _init(p: Vector2, h, f: float, d: float) -> void:
		pos = p
		hero = h
		facing = f
		dur = d

	func draw(ci: CanvasItem) -> void:
		var a := (1.0 - t / dur) * 0.4
		hero.draw_body(ci, pos, 17.0, facing, 0.0, {"alpha": a, "moving": true})


## Cone de gelo do Titã Solar
class Cone extends Base:
	var pos: Vector2
	var angle: float
	var length: float
	var arc: float
	var color: Color

	func _init(p: Vector2, a: float, l: float, ar: float, col: Color) -> void:
		pos = p
		angle = a
		length = l
		arc = ar
		color = col
		dur = 0.45

	func draw(ci: CanvasItem) -> void:
		var k := t / dur
		var reach := length * minf(1.0, k * 3.0)
		var pts := PackedVector2Array([pos])
		for i in 13:
			pts.append(pos + Vector2.from_angle(angle - arc / 2.0 + arc * i / 12.0) * reach)
		ci.draw_colored_polygon(pts, Color(color, (1.0 - k) * 0.45))
		for i in 6:
			var a := angle + randf_range(-arc / 2.0, arc / 2.0)
			var d := randf() * reach
			ci.draw_circle(pos + Vector2.from_angle(a) * d, randf_range(2, 5), Color(1, 1, 1, 1.0 - k))


## Nuvem de fumaça do Vigia Noturno (no chão)
class Smoke extends Base:
	var pos: Vector2
	var radius: float
	var puffs := []

	func _init(p: Vector2, r: float, d: float) -> void:
		under = true
		pos = p
		radius = r
		dur = d
		for i in 16:
			puffs.append([Vector2.from_angle(randf() * TAU) * randf() * r * 0.8, randf_range(r * 0.25, r * 0.45), randf() * TAU])

	func draw(ci: CanvasItem) -> void:
		var a := minf(1.0, (dur - t) / 0.6) * minf(1.0, t / 0.15)
		for pf in puffs:
			var o: Vector2 = pf[0]
			var wob: float = sin(t * 2.0 + pf[2]) * 6.0
			ci.draw_circle(pos + o + Vector2(wob, 0), pf[1], Color(0.35, 0.36, 0.42, 0.28 * a))


## Teia gigante do Aracnídeo (no chão)
class Web extends Base:
	var pos: Vector2
	var radius: float

	func _init(p: Vector2, r: float, d: float) -> void:
		under = true
		pos = p
		radius = r
		dur = d

	func draw(ci: CanvasItem) -> void:
		var a := minf(1.0, (dur - t) / 0.5)
		var grow := minf(1.0, t / 0.15)
		var col := Color(1, 1, 1, 0.75 * a)
		var R := radius * grow
		for i in 10:
			ci.draw_line(pos, pos + Vector2.from_angle(TAU * i / 10.0) * R, col, 1.5, true)
		for ring in [0.3, 0.55, 0.8, 1.0]:
			var pts := PackedVector2Array()
			for i in 11:
				pts.append(pos + Vector2.from_angle(TAU * i / 10.0) * R * ring)
			ci.draw_polyline(pts, col, 1.5, true)
