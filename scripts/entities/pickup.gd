class_name Pickup
extends RefCounted
## Coletáveis: cristal (experiência + ouro), coração (cura) e baú (item grátis).

var kind := "gem"
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var value := 1
var gold := 0
var magnet := false
var speed := 0.0
var t := 0.0
var dead := false


static func make(k: String, p: Vector2, v: int = 1, g: int = 0) -> Pickup:
	var pk := Pickup.new()
	pk.kind = k
	pk.pos = p
	pk.value = v
	pk.gold = g
	pk.t = randf() * 10.0
	if k != "chest":
		pk.vel = Vector2.from_angle(randf() * TAU) * randf_range(30, 130)
	return pk


func update(dt: float, game: Game) -> void:
	var p := game.player
	var to := p.position - pos
	var d := maxf(to.length(), 0.001)
	var reach: float = 50.0 if kind == "chest" else p.stats.pickup_range
	if not magnet and d < reach:
		magnet = true
	if magnet:
		speed = maxf(speed, 180.0) + 1500.0 * dt
		pos += to / d * minf(speed * dt, d)
	else:
		pos += vel * dt
		vel *= exp(-dt * 6.0)
	if d < p.r + 8.0:
		dead = true
		game.collect(self)
