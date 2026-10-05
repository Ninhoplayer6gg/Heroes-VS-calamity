class_name Boss
extends Enemy
## Chefe: alterna entre perseguir e atacar (anel de projéteis, investida,
## invocação de lacaios e espiral). Abaixo de 50% de vida entra em fúria.

var last_attack := ""
var rage := false
var shots := 0
var shot_t := 0.0
var charges := 0
var spiral_a := 0.0


func setup_boss(d: Dictionary, p: Vector2) -> Boss:
	def = d
	pos = p
	boss = true
	max_hp = d.hp
	hp = max_hp
	damage = d.damage
	speed = d.speed
	r = d.radius
	xp = d.xp
	color = d.color
	kb_resist = 0.97
	state = "chase"
	state_t = 2.5
	return self


func next_attack() -> void:
	var options: Array = def.attacks.filter(func(a): return a != last_attack)
	var a: String = options.pick_random()
	last_attack = a
	state = a
	match a:
		"ring":
			shots = 5 if rage else 3
			shot_t = 0.3
		"charge":
			charges = 3 if rage else 2
			state = "aim"
			state_t = 0.8
		"summon":
			state_t = 1.0
		"spiral":
			state_t = 3.2
			shot_t = 0.0
			spiral_a = 0.0


func to_chase() -> void:
	state = "chase"
	state_t = randf_range(1.2, 2.0) if rage else randf_range(2.0, 3.2)


func update(dt: float, game: Game) -> void:
	tick_status(dt)
	if freeze_t > 0.0:
		return
	t += dt
	if not rage and hp < max_hp * 0.5:
		rage = true
		game.add_text(pos + Vector2(0, -r - 20), "FÚRIA!", Color("ff5d5d"), 34, true)
		game.shake(8.0)
	var p := game.player
	var to := p.position - pos
	var d := maxf(to.length(), 0.001)
	var m := to / d
	var sp := speed * (1.25 if rage else 1.0)

	match state:
		"chase":
			state_t -= dt
			if state_t <= 0.0:
				next_attack()
		"ring":
			sp *= 0.3
			shot_t -= dt
			if shot_t <= 0.0:
				shot_t = 0.45
				var n := 22 if def.id == "calamity" else 16
				var off := randf() * TAU
				for i in n:
					game.enemy_shoot(pos, off + TAU * i / n, 200.0, damage * 0.6, Color("ff5d73"))
				shots -= 1
				if shots <= 0:
					to_chase()
		"aim":
			sp = 0.0
			state_t -= dt
			if state_t > 0.25:
				charge_dir = m
			if state_t <= 0.0:
				state = "charge"
				state_t = 0.75
		"charge":
			m = charge_dir
			sp = speed * 6.5
			state_t -= dt
			if randf() < 0.7:
				game.particle(pos + Vector2(0, r * 0.6), Vector2(randf_range(-60, 60), randf_range(-60, 0)), 0.5, Color("4a2a2a"), 6.0)
			if state_t <= 0.0:
				charges -= 1
				if charges > 0:
					state = "aim"
					state_t = 0.55
				else:
					to_chase()
		"summon":
			sp = 0.0
			state_t -= dt
			if state_t <= 0.0:
				var types: Array = ["wraith", "bomber", "brute", "cultist"] if def.id == "calamity" else ["bat", "slime", "cultist"]
				for i in (5 if rage else 3):
					var a := randf() * TAU
					game.queue_group(3, false, types.pick_random(), pos + Vector2.from_angle(a) * 160.0)
				game.add_fx(Fx.Ring.new(pos, 180.0, Color("b23a48"), 0.5, 6.0))
				to_chase()
		"spiral":
			sp = 0.0
			state_t -= dt
			shot_t -= dt
			if shot_t <= 0.0:
				shot_t = 0.09
				spiral_a += 0.33
				for k in 3:
					game.enemy_shoot(pos, spiral_a + TAU * k / 3.0, 230.0, damage * 0.55, Color("ff9f1a"))
			if state_t <= 0.0:
				to_chase()

	pos += m * sp * move_factor() * dt
	pos = pos.clamp(Vector2(r, r), Config.ARENA - Vector2(r, r))


func draw(ci: CanvasItem, t_game: float, player_x: float) -> void:
	if state == "aim":
		ci.draw_line(pos, pos + charge_dir * 520.0, Color(1, 0.24, 0.15, 0.3), r * 1.6, true)
	Art.boss(ci, self, t_game, player_x)
