class_name SpatialGrid
extends RefCounted
## Grade espacial: acelera a busca de inimigos próximos de um ponto

var cs: float
var cols: int
var rows: int
var cells: Array = []


func _init(size: Vector2, cell_size: float) -> void:
	cs = cell_size
	cols = int(ceil(size.x / cs)) + 1
	rows = int(ceil(size.y / cs)) + 1
	cells.resize(cols * rows)
	for i in cells.size():
		cells[i] = []


func clear() -> void:
	for c in cells:
		c.clear()


func insert(e) -> void:
	var cx := clampi(int(e.pos.x / cs), 0, cols - 1)
	var cy := clampi(int(e.pos.y / cs), 0, rows - 1)
	cells[cy * cols + cx].append(e)


## Preenche `out` com os objetos das células que tocam o círculo (p, r)
func query(p: Vector2, r: float, out: Array) -> Array:
	out.clear()
	var x0 := clampi(int((p.x - r) / cs), 0, cols - 1)
	var x1 := clampi(int((p.x + r) / cs), 0, cols - 1)
	var y0 := clampi(int((p.y - r) / cs), 0, rows - 1)
	var y1 := clampi(int((p.y + r) / cs), 0, rows - 1)
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			out.append_array(cells[cy * cols + cx])
	return out
