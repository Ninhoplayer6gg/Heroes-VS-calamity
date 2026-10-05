class_name Icons
## Ícones desenhados em código (atributos, itens, armas e habilidades).
## Uso: Icons.draw(canvas_item, "heart", centro, meio_tamanho, cor)

const INK := Color(0.07, 0.04, 0.06, 0.9)


static func draw(ci: CanvasItem, icon: String, c: Vector2, s: float, col: Color) -> void:
	var w := maxf(1.5, s * 0.14)
	match icon:
		"heart":
			var pts := PackedVector2Array()
			for i in 32:
				var t := TAU * i / 32.0
				pts.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * s / 17.0)
			U.poly(ci, pts, col, INK, w)
		"cross":
			U.disc(ci, c, s * 0.9, col, INK, w)
			ci.draw_rect(Rect2(c - Vector2(s * 0.18, s * 0.55), Vector2(s * 0.36, s * 1.1)), Color.WHITE)
			ci.draw_rect(Rect2(c - Vector2(s * 0.55, s * 0.18), Vector2(s * 1.1, s * 0.36)), Color.WHITE)
		"shield":
			U.poly(ci, PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.85, -s * 0.6), c + Vector2(s * 0.7, s * 0.3), c + Vector2(0, s), c + Vector2(-s * 0.7, s * 0.3), c + Vector2(-s * 0.85, -s * 0.6)]), col, INK, w)
			ci.draw_line(c + Vector2(0, -s * 0.7), c + Vector2(0, s * 0.7), Color(1, 1, 1, 0.5), w, true)
		"sword":
			U.poly(ci, PackedVector2Array([c + Vector2(-s * 0.15, s * 0.35), c + Vector2(-s * 0.15, -s * 0.7), c + Vector2(0, -s), c + Vector2(s * 0.15, -s * 0.7), c + Vector2(s * 0.15, s * 0.35)]), col, INK, w)
			ci.draw_line(c + Vector2(-s * 0.5, s * 0.4), c + Vector2(s * 0.5, s * 0.4), INK, w * 2.2, true)
			ci.draw_line(c + Vector2(0, s * 0.45), c + Vector2(0, s * 0.95), Color("7a5230"), w * 2.2, true)
		"clock":
			U.disc(ci, c, s * 0.9, col, INK, w)
			ci.draw_line(c, c + Vector2(0, -s * 0.6), INK, w * 1.3, true)
			ci.draw_line(c, c + Vector2(s * 0.45, s * 0.1), INK, w * 1.3, true)
		"target":
			U.disc(ci, c, s * 0.9, col, INK, w)
			U.disc(ci, c, s * 0.55, Color.WHITE, INK, w)
			U.disc(ci, c, s * 0.22, col)
		"speed":
			for k in 2:
				var o := Vector2(-s * 0.35 + k * s * 0.55, 0)
				ci.draw_polyline(PackedVector2Array([c + o + Vector2(-s * 0.3, -s * 0.7), c + o + Vector2(s * 0.3, 0), c + o + Vector2(-s * 0.3, s * 0.7)]), col, s * 0.32, true)
		"burst":
			var pts := PackedVector2Array()
			for i in 16:
				var rr := s if i % 2 == 0 else s * 0.5
				pts.append(c + Vector2.from_angle(TAU * i / 16.0 - PI / 2) * rr)
			U.poly(ci, pts, col, INK, w)
		"magnet":
			ci.draw_arc(c + Vector2(0, -s * 0.05), s * 0.55, PI, TAU, 16, col, s * 0.38, true)
			ci.draw_line(c + Vector2(-s * 0.55, -s * 0.05), c + Vector2(-s * 0.55, s * 0.7), col, s * 0.38)
			ci.draw_line(c + Vector2(s * 0.55, -s * 0.05), c + Vector2(s * 0.55, s * 0.7), col, s * 0.38)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.74, s * 0.45), Vector2(s * 0.38, s * 0.3)), Color.WHITE)
			ci.draw_rect(Rect2(c + Vector2(s * 0.36, s * 0.45), Vector2(s * 0.38, s * 0.3)), Color.WHITE)
		"wind":
			for k in 3:
				var y := (k - 1) * s * 0.5
				ci.draw_arc(c + Vector2(s * 0.25 - k * s * 0.1, y - s * 0.2), s * 0.22, PI * 0.5, PI * 2.2, 10, col, w * 1.4, true)
				ci.draw_line(c + Vector2(-s * 0.9, y), c + Vector2(s * 0.25 - k * s * 0.1, y), col, w * 1.4, true)
		"drop":
			var pts := PackedVector2Array([c + Vector2(0, -s)])
			for i in 13:
				pts.append(c + Vector2(0, s * 0.3) + Vector2.from_angle(-PI * 0.2 + PI * 1.4 * i / 12.0) * s * 0.62)
			U.poly(ci, pts, col, INK, w)
		"bolt":
			U.poly(ci, PackedVector2Array([c + Vector2(s * 0.2, -s), c + Vector2(-s * 0.55, s * 0.12), c + Vector2(-s * 0.02, s * 0.12), c + Vector2(-s * 0.25, s), c + Vector2(s * 0.6, -s * 0.2), c + Vector2(s * 0.05, -s * 0.2)]), col, INK, w)
		"gem":
			U.poly(ci, PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.7, 0), c + Vector2(0, s), c + Vector2(-s * 0.7, 0)]), col, INK, w)
			U.poly(ci, PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.28, -s * 0.15), c + Vector2(-s * 0.2, 0)]), Color(1, 1, 1, 0.55))
		"clover":
			for a in [0.0, PI / 2, PI, PI * 1.5]:
				U.disc(ci, c + Vector2.from_angle(a - PI / 4) * s * 0.42, s * 0.38, col, INK, w)
			ci.draw_line(c, c + Vector2(s * 0.3, s * 0.95), Color("2f6b2a"), w * 1.5, true)
		"coin":
			U.disc(ci, c, s * 0.85, Config.C_GOLD, Color("5a3d08"), w)
			U.disc(ci, c, s * 0.55, Color("ffe08a"))
		"plus":
			for k in 3:
				U.disc(ci, c + Vector2.from_angle(-PI / 2 + (k - 1) * 0.7) * s * 0.55 + Vector2(0, s * 0.25), s * 0.28, col, INK, w)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.08, -s * 0.95), Vector2(s * 0.16, s * 0.5)), Color.WHITE)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.25, -s * 0.78), Vector2(s * 0.5, s * 0.16)), Color.WHITE)
		"star":
			var pts := PackedVector2Array()
			for i in 10:
				var rr := s if i % 2 == 0 else s * 0.42
				pts.append(c + Vector2.from_angle(TAU * i / 10.0 - PI / 2) * rr)
			U.poly(ci, pts, col, INK, w)
		"crown":
			U.poly(ci, PackedVector2Array([c + Vector2(-s, s * 0.6), c + Vector2(-s, -s * 0.4), c + Vector2(-s * 0.5, s * 0.05), c + Vector2(0, -s * 0.75), c + Vector2(s * 0.5, s * 0.05), c + Vector2(s, -s * 0.4), c + Vector2(s, s * 0.6)]), col, INK, w)
		"snow":
			for i in 3:
				var d := Vector2.from_angle(PI * i / 3.0) * s
				ci.draw_line(c - d, c + d, col, w * 1.6, true)
			U.disc(ci, c, s * 0.2, Color.WHITE)
		"rocket":
			U.poly(ci, PackedVector2Array([c + Vector2(s, -s), c + Vector2(s * 0.1, s * 0.35), c + Vector2(-s * 0.35, -s * 0.1)]), col, INK, w)
			U.poly(ci, PackedVector2Array([c + Vector2(-s * 0.2, s * 0.2), c + Vector2(-s * 0.9, s * 0.9), c + Vector2(-s * 0.05, s * 0.55)]), Config.C_EMBER)
		"web":
			for i in 6:
				ci.draw_line(c, c + Vector2.from_angle(TAU * i / 6.0) * s, col, w, true)
			for rr in [0.4, 0.75]:
				var pts := PackedVector2Array()
				for i in 7:
					pts.append(c + Vector2.from_angle(TAU * i / 6.0) * s * rr)
				ci.draw_polyline(pts, col, w, true)
		"cloud":
			for o in [Vector2(-0.45, 0.15), Vector2(0.45, 0.15), Vector2(0, -0.2), Vector2(0, 0.3)]:
				U.disc(ci, c + o * s, s * 0.48, col)
		"fist":
			U.poly(ci, PackedVector2Array([c + Vector2(-s * 0.7, -s * 0.45), c + Vector2(s * 0.6, -s * 0.65), c + Vector2(s * 0.85, -s * 0.2), c + Vector2(s * 0.8, s * 0.45), c + Vector2(-s * 0.1, s * 0.75), c + Vector2(-s * 0.8, s * 0.35)]), col, INK, w)
			for k in 3:
				ci.draw_line(c + Vector2(-s * 0.35 + k * s * 0.38, -s * 0.5), c + Vector2(-s * 0.3 + k * s * 0.38, s * 0.05), INK, w, true)
		"feather":
			U.ellipse(ci, c, s * 0.38, s * 0.95, col, 0.6)
			ci.draw_line(c + Vector2(-s * 0.7, s * 0.8), c + Vector2(s * 0.45, -s * 0.6), INK, w, true)
		"eye":
			U.ellipse(ci, c, s, s * 0.55, Color.WHITE)
			U.disc(ci, c, s * 0.42, col)
			U.disc(ci, c, s * 0.18, INK)
		"ring":
			ci.draw_circle(c, s * 0.75, col, false, s * 0.3, true)
			U.disc(ci, c + Vector2(0, -s * 0.75), s * 0.3, Color.WHITE, col, w)
		"hammer":
			ci.draw_line(c + Vector2(-s * 0.1, -s * 0.1), c + Vector2(s * 0.55, s * 0.9), Color("7a5230"), w * 2.2, true)
			ci.draw_set_transform(c, -0.6, Vector2.ONE)
			ci.draw_rect(Rect2(Vector2(-s * 0.75, -s * 0.85), Vector2(s * 1.2, s * 0.75)), col)
			ci.draw_rect(Rect2(Vector2(-s * 0.75, -s * 0.85), Vector2(s * 1.2, s * 0.75)), INK, false, w)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"palm":
			U.disc(ci, c, s * 0.95, Color(col, 0.35))
			U.disc(ci, c, s * 0.6, col, INK, w)
			U.disc(ci, c, s * 0.3, Color.WHITE)
		"lasso":
			ci.draw_arc(c + Vector2(0, -s * 0.15), s * 0.6, 0, TAU, 20, col, w * 1.6, true)
			ci.draw_polyline(PackedVector2Array([c + Vector2(s * 0.3, s * 0.35), c + Vector2(s * 0.2, s * 0.7), c + Vector2(s * 0.6, s)]), col, w * 1.6, true)
		"bat":
			U.poly(ci, PackedVector2Array([c + Vector2(-s, -s * 0.25), c + Vector2(-s * 0.55, -s * 0.05), c + Vector2(-s * 0.3, -s * 0.35), c + Vector2(0, s * 0.05), c + Vector2(s * 0.3, -s * 0.35), c + Vector2(s * 0.55, -s * 0.05), c + Vector2(s, -s * 0.25), c + Vector2(s * 0.6, s * 0.35), c + Vector2(0, s * 0.55), c + Vector2(-s * 0.6, s * 0.35)]), col, INK, w)
		"grenade":
			U.disc(ci, c + Vector2(0, s * 0.15), s * 0.7, col, INK, w)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, -s * 0.8), Vector2(s * 0.4, s * 0.3)), INK)
			U.disc(ci, c + Vector2(-s * 0.2, -s * 0.05), s * 0.18, Color(1, 1, 1, 0.6))
		"drone":
			ci.draw_line(c + Vector2(-s, -s * 0.45), c + Vector2(s, -s * 0.45), INK, w * 1.2, true)
			U.ellipse(ci, c + Vector2(-s * 0.75, -s * 0.55), s * 0.3, s * 0.08, col)
			U.ellipse(ci, c + Vector2(s * 0.75, -s * 0.55), s * 0.3, s * 0.08, col)
			U.disc(ci, c + Vector2(0, s * 0.1), s * 0.5, col, INK, w)
			U.disc(ci, c + Vector2(0, s * 0.15), s * 0.2, Config.C_HP)
		"coil":
			for k in 4:
				U.ellipse(ci, c + Vector2(0, s * 0.6 - k * s * 0.38), s * 0.55, s * 0.16, col)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.7), c + Vector2(0, -s), c + Vector2(-s * 0.15, -s * 0.85), c + Vector2(s * 0.45, -s * 0.95)]), Color.WHITE, w, true)
		"field":
			ci.draw_circle(c, s * 0.9, Color(col, 0.3), true, -1.0, true)
			ci.draw_circle(c, s * 0.9, col, false, w * 1.4, true)
			U.disc(ci, c, s * 0.3, col)
		"orbit":
			ci.draw_circle(c, s * 0.65, Color(col, 0.5), false, w, true)
			for i in 3:
				U.disc(ci, c + Vector2.from_angle(TAU * i / 3.0) * s * 0.65, s * 0.25, col, INK, w)
		_:
			U.disc(ci, c, s * 0.8, col, INK, w)
