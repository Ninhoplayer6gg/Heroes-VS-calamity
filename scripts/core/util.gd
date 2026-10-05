class_name U
## Funções utilitárias (matemática, sorteio, formatação)

## Pontos de um círculo unitário, usados para desenhar elipses rapidamente
static var UNIT_CIRCLE: PackedVector2Array = _make_unit_circle(24)


static func _make_unit_circle(n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		pts.append(Vector2.from_angle(TAU * i / n))
	return pts


static func chance(p: float) -> bool:
	return randf() < p


static func norm_angle(a: float) -> float:
	return wrapf(a, -PI, PI)


static func dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len2 := ab.length_squared()
	var t := 0.0
	if len2 > 0.0:
		t = clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## entries: Array de Dictionary com a chave "weight"
static func weighted_pick(entries: Array) -> Dictionary:
	var total := 0.0
	for e in entries:
		total += e.weight
	var r := randf() * total
	for e in entries:
		r -= e.weight
		if r <= 0.0:
			return e
	return entries[entries.size() - 1]


static func fmt_num(v: float, decimals: int = 1) -> String:
	return String.num(v, decimals).replace(".", ",")


## Desenha uma elipse preenchida
static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, rot: float = 0.0) -> void:
	ci.draw_set_transform(c, rot, Vector2(rx, ry))
	ci.draw_colored_polygon(UNIT_CIRCLE, color)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Polígono preenchido com contorno suavizado
static func poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, outline: Color = Color.TRANSPARENT, width: float = 2.0) -> void:
	ci.draw_colored_polygon(pts, fill)
	if outline.a > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, outline, width, true)


## Círculo com contorno suavizado
static func disc(ci: CanvasItem, c: Vector2, r: float, fill: Color, outline: Color = Color.TRANSPARENT, width: float = 2.5) -> void:
	ci.draw_circle(c, r, fill, true, -1.0, true)
	if outline.a > 0.0:
		ci.draw_circle(c, r, outline, false, width, true)
