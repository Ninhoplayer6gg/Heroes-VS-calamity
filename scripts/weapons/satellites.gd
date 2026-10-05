extends OrbitWeapon
## Satélites Orbitais: esferas de energia giram ao seu redor.


func _init() -> void:
	super()
	name = "Satélites Orbitais"
	desc = "Esferas de energia giram ao seu redor cortando quem encostar."
	icon = "orbit"
	color = Color("c7b8ff")


func stats(lv: int) -> Dictionary:
	return {"damage": 8 + 4 * lv, "count": [2, 3, 3, 4, 5][lv - 1], "radius": 85, "spin": 3.2 + 0.3 * lv}


func draw_piece(ci: CanvasItem, c: Vector2, _a: float, _slot: WeaponSlot) -> void:
	U.disc(ci, c, 16.0, Color(color, 0.25))
	U.disc(ci, c, 9.0, Color("e9e4ff"), Color("6b5fb0"), 2.0)
