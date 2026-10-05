class_name Projectile
extends RefCounted
## Projétil do jogador (ou do inimigo, se hostile = true).

var kind := "orb"
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var r := 6.0
var damage := 10.0
var pierce := 0
var bounces := 0
var explode := 0.0           # raio da explosão ao acertar (0 = não explode)
var homing := 0.0            # velocidade de curva (rad/s) para teleguiados
var gravity := 0.0
var knockback := 120.0
var life := 2.0
var spin := 0.0
var rot := 0.0
var color := Color.WHITE
var target: Enemy = null
var boomerang := 0.0         # tempo de ida antes de voltar para o jogador
var returning := false
var slow := 0.0              # fator de lentidão aplicado (0 = nenhum)
var slow_time := 0.0
var hostile := false
var hit := {}
var dead := false


static func make(o: Dictionary) -> Projectile:
	var p := Projectile.new()
	for k in o:
		p.set(k, o[k])
	return p


func update(dt: float, game: Game) -> void:
	life -= dt
	if life <= 0.0:
		dead = true
		return
	if homing > 0.0:
		if target == null or target.dead:
			target = game.nearest_enemy(pos, 700.0, hit)
		if target:
			var sp := vel.length()
			var cur := vel.angle()
			var want := (target.pos - pos).angle()
			var diff := U.norm_angle(want - cur)
			vel = Vector2.from_angle(cur + clampf(diff, -homing * dt, homing * dt)) * sp
	if boomerang > 0.0:
		boomerang -= dt
		if boomerang <= 0.0 and not returning:
			returning = true
			hit.clear()
		if returning:
			var to := game.player.position - pos
			var sp2 := maxf(vel.length(), 520.0)
			vel = vel.lerp(to.normalized() * sp2, minf(1.0, dt * 8.0))
			if to.length() < 24.0:
				dead = true
	if gravity != 0.0:
		vel.y += gravity * dt
	pos += vel * dt
	rot += spin * dt

	if kind == "grenade" and randf() < 0.5:
		game.particle(pos, Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.3, Color("b67cff"), 4.0)
	elif kind == "missile" and randf() < 0.7:
		game.particle(pos - vel.normalized() * 12.0, Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.3, Color("ffb35c"), 4.0)

	var m := 400.0 if (gravity != 0.0 or boomerang > 0.0 or returning) else 60.0
	if pos.x < -m or pos.x > Config.ARENA.x + m or pos.y < -m or pos.y > Config.ARENA.y + m:
		dead = true
