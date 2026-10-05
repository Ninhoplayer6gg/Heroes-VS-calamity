class_name Enemy
extends RefCounted
## Inimigo comum. Os dados de cada tipo ficam em EnemyDB.TYPES.
## Comportamentos: chase, zigzag, ranged, bomber, charger, phase

var def: Dictionary
var pos := Vector2.ZERO
var r := 15.0
var hp := 10.0
var max_hp := 10.0
var damage := 5.0
var speed := 70.0
var xp := 1
var color := Color.WHITE
var elite := false
var boss := false
var kb := Vector2.ZERO
var kb_resist := 0.0
var flash := 0.0
var t := 0.0
var state := "move"
var state_t := 0.0
var shoot_t := 0.0
var strafe := 1.0
var charge_dir := Vector2.RIGHT
var wander := Vector2.ZERO
var orbit_hit := -9.0
var trail_hit := -9.0
var slow_t := 0.0
var slow_f := 1.0
var freeze_t := 0.0
var root_t := 0.0
var dead := false


func setup(d: Dictionary, p: Vector2, wave: int, is_elite: bool = false) -> Enemy:
	def = d
	pos = p
	elite = is_elite
	max_hp = d.hp * Game.hp_scale(wave) * (7.0 if elite else 1.0)
	hp = max_hp
	damage = d.damage * Game.dmg_scale(wave) * (1.3 if elite else 1.0)
	speed = d.speed * (1.0 + (wave - 1) * 0.012) * randf_range(0.9, 1.1)
	r = d.radius * (1.45 if elite else 1.0)
	xp = d.xp * (12 if elite else 1)
	color = d.color
	kb_resist = maxf(d.get("kb_resist", 0.0), 0.6) if elite else d.get("kb_resist", 0.0)
	t = randf() * 10.0
	state_t = randf_range(1.5, 3.5)
	shoot_t = randf_range(1.0, d.get("shoot_cooldown", 2.0))
	strafe = 1.0 if randf() < 0.5 else -1.0
	return self


## Efeitos de controle (o mais forte prevalece)
func apply_slow(factor: float, duration: float) -> void:
	if slow_t <= 0.0 or factor < slow_f:
		slow_f = factor
	slow_t = maxf(slow_t, duration)


func apply_freeze(duration: float) -> void:
	freeze_t = maxf(freeze_t, duration * (0.4 if boss else 1.0))


func apply_root(duration: float) -> void:
	root_t = maxf(root_t, duration * (0.4 if boss else 1.0))


## Multiplicador de movimento causado por lentidão/congelamento/teia
func move_factor() -> float:
	if freeze_t > 0.0 or root_t > 0.0:
		return 0.0
	return slow_f if slow_t > 0.0 else 1.0


func tick_status(dt: float) -> void:
	flash = maxf(0.0, flash - dt)
	slow_t = maxf(0.0, slow_t - dt)
	freeze_t = maxf(0.0, freeze_t - dt)
	root_t = maxf(0.0, root_t - dt)


func update(dt: float, game: Game) -> void:
	tick_status(dt)
	if freeze_t > 0.0:
		_apply_knockback(dt)
		return
	t += dt
	var p := game.player
	var target := p.position
	# Invisível (bomba de fumaça): os inimigos vagam sem rumo
	if p.stealth > 0.0:
		if wander == Vector2.ZERO or pos.distance_to(wander) < 20.0:
			wander = (pos + Vector2(randf_range(-200, 200), randf_range(-200, 200))).clamp(Vector2.ZERO, Config.ARENA)
		target = wander
	var to := target - pos
	var d := maxf(to.length(), 0.001)
	var n := to / d
	var m := n
	var sp := speed

	match def.behavior:
		"zigzag":
			var w := sin(t * 5.0) * 0.9
			m = n + Vector2(-n.y, n.x) * w
		"ranged":
			if d < 200.0:
				m = -n
			elif d < 300.0:
				m = Vector2(-n.y, n.x) * 0.6 * strafe
			shoot_t -= dt
			if shoot_t <= 0.0 and d < 500.0 and p.stealth <= 0.0:
				shoot_t = def.shoot_cooldown * randf_range(0.8, 1.2)
				game.enemy_shoot(pos, n.angle(), def.bullet_speed, damage * 0.85, Color("d64570"))
		"bomber":
			if state == "fuse":
				sp = 0.0
				state_t -= dt
				if state_t <= 0.0:
					explode(game)
			elif d < 55.0 + r and p.stealth <= 0.0:
				state = "fuse"
				state_t = 0.55
		"charger":
			if state == "move":
				state_t -= dt
				if state_t <= 0.0 and d < 430.0 and p.stealth <= 0.0:
					state = "aim"
					state_t = 0.65
			elif state == "aim":
				sp = 0.0
				if state_t > 0.25:
					charge_dir = n
				state_t -= dt
				if state_t <= 0.0:
					state = "charge"
					state_t = 0.55
			else:
				m = charge_dir
				sp = speed * 7.0
				state_t -= dt
				if randf() < 0.5:
					game.particle(pos + Vector2(0, r * 0.8), Vector2(randf_range(-30, 30), randf_range(-40, -10)), 0.4, Color("5a4a3f"), 4.0)
				if state_t <= 0.0:
					state = "move"
					state_t = randf_range(2.5, 4.0)

	pos += m * sp * move_factor() * dt
	_apply_knockback(dt)


func _apply_knockback(dt: float) -> void:
	pos += kb * dt
	kb *= exp(-dt * 9.0)
	pos = pos.clamp(Vector2(r, r), Config.ARENA - Vector2(r, r))


func explode(game: Game) -> void:
	var R := 80.0
	game.explosion(pos, R, Color("ff8c2a"))
	var p := game.player
	if pos.distance_to(p.position) < R + p.r:
		p.take_damage(damage, game)
	dead = true


func draw(ci: CanvasItem, t_game: float, player_x: float) -> void:
	if def.behavior == "charger" and state == "aim":
		ci.draw_line(pos, pos + charge_dir * 260.0, Color(1, 0.3, 0.25, 0.35), r * 1.4, true)
	Art.enemy(ci, self, t_game, player_x)
