extends OrbitWeapon
## Sentinela Esmeralda: construtos de energia verde que giram em volta.

const SHAPES := ["fist", "shield", "hammer", "star"]


func _init() -> void:
	super()
	name = "Construtos do Anel"
	desc = "Construtos de energia verde giram ao seu redor."
	icon = "ring"
	color = Color("35e07a")
	hero_only = "emerald_sentinel"


func stats(lv: int) -> Dictionary:
	return {"damage": 9 + 4 * lv, "count": [2, 3, 3, 4, 5][lv - 1], "radius": 90, "spin": 3.0 + 0.3 * lv}


func draw_piece(ci: CanvasItem, c: Vector2, a: float, _slot: WeaponSlot) -> void:
	var i := int(posmod(roundi(a / (TAU / 5.0)), SHAPES.size()))
	U.disc(ci, c, 17.0, Color(color, 0.18))
	Icons.draw(ci, SHAPES[i], c, 13.0, Color(0.55, 1.0, 0.7, 0.95))
