extends Node2D
## Pinta o chão da arena uma única vez dentro de um SubViewport.
## A textura resultante é exibida pelo Sprite2D "Floor" (bem mais leve do que redesenhar).

const MARGIN := 240.0


func _ready() -> void:
	position = Vector2(MARGIN, MARGIN)


func _draw() -> void:
	var W := Config.ARENA.x
	var H := Config.ARENA.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	draw_rect(Rect2(-MARGIN, -MARGIN, W + MARGIN * 2.0, H + MARGIN * 2.0), Color("07050a"))
	draw_rect(Rect2(0, 0, W, H), Color("1e1622"))

	for i in 700:
		var col := Color(1.0, 0.86, 0.9, 0.02) if rng.randf() < 0.45 else Color(0, 0, 0, 0.07)
		draw_circle(Vector2(rng.randf() * W, rng.randf() * H), 8.0 + rng.randf() * 60.0, col)

	# lajes gastas
	var tile := 120.0
	var y := 0.0
	while y <= H:
		var x := 0.0
		while x <= W:
			if rng.randf() < 0.55:
				draw_rect(Rect2(x + rng.randf() * 6.0, y + rng.randf() * 6.0, tile - rng.randf() * 10.0, tile - rng.randf() * 10.0), Color(0, 0, 0, 0.22), false, 2.0)
			x += tile
		y += tile

	# rachaduras com brasas da Calamidade
	for i in 30:
		var p := Vector2(rng.randf() * W, rng.randf() * H)
		var a := rng.randf() * TAU
		var pts := PackedVector2Array([p])
		for j in 6 + rng.randi() % 10:
			a += (rng.randf() - 0.5) * 1.3
			p += Vector2.from_angle(a) * (14.0 + rng.randf() * 28.0)
			pts.append(p)
		draw_polyline(pts, Color(1.0, 0.35, 0.16, 0.07), 12.0, true)
		draw_polyline(pts, Color(0, 0, 0, 0.6), 4.0, true)
		draw_polyline(pts, Color(1.0, 0.47, 0.2, 0.55), 1.4, true)

	# pedras
	for i in 140:
		var c := Vector2(rng.randf() * W, rng.randf() * H)
		var r := 3.0 + rng.randf() * 8.0
		U.ellipse(self, c, r, r * 0.75, Color("2d2433"), rng.randf() * TAU)
		U.ellipse(self, c + Vector2(-r * 0.2, -r * 0.25), r * 0.5, r * 0.3, Color(1, 1, 1, 0.05))

	# muralha da arena
	draw_rect(Rect2(-9, -9, W + 18, H + 18), Color("2c1c33"), false, 18.0)
	draw_rect(Rect2(1, 1, W - 2, H - 2), Color(1.0, 0.42, 0.24, 0.45), false, 2.0)
