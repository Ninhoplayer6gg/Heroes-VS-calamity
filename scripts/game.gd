class_name Game
extends Node2D
## Núcleo do jogo: estados, ondas, spawn, combate, coleta e câmera.
## Fluxo: MENU → PLAYING ⇄ (LEVELUP | PAUSED) → CLEAR → SHOP → PLAYING ... → DEAD/OVER | VICTORY

enum State { MENU, PLAYING, LEVELUP, PAUSED, CLEAR, SHOP, DEAD, OVER, VICTORY }

## Acesso global à partida atual (Game.I)
static var I: Game

@onready var camera: Camera2D = $World/Camera
@onready var player: Player = $World/Player
@onready var ui: GameUI = $UI/Root
@onready var vignette: ColorRect = $Overlay/Vignette
@onready var layers: Array = [$World/Ground, $World/Pickups, $World/Enemies, $World/Projectiles, $World/Top]

var state := State.MENU
var time := 0.0
var real_time := 0.0
var hero: HeroBase

var enemies: Array = []
var projectiles: Array = []
var enemy_bullets: Array = []
var pickups: Array = []
var fx_under: Array = []
var fx_top: Array = []
var particles: Array = []
var texts: Array = []
var timers: Array = []
var spawn_queue: Array = []

var wave := 0
var wave_time := 0.0
var wave_duration := 0.0
var is_boss_wave := false
var boss: Boss = null
var boss_defeated := false
var spawn_acc := 0.0
var elite_spawned := false
var wave_ended := false
var clear_timer := 0.0
var dead_timer := 0.0
var pending_levels := 0
var kills := 0
var run_time := 0.0
var shop_offers: Array = []
var shop_rerolls := 0
var time_slow := 0.0
var afterimage_t := 0.0
var shake_amt := 0.0

var grid := SpatialGrid.new(Config.ARENA, 64.0)
var touch_move := Vector2.ZERO
var touch_ability := false


func _ready() -> void:
	I = self
	var floor_vp: SubViewport = $World/FloorViewport
	floor_vp.size = Vector2i(Config.ARENA) + Vector2i(480, 480)
	$World/Floor.texture = floor_vp.get_texture()
	camera.position = Config.ARENA / 2.0
	player.visible = false
	ui.setup(self)
	ui.show_menu()


func _exit_tree() -> void:
	# libera os caches estáticos para não sobrar nada na memória ao fechar
	WeaponDB._cache.clear()
	HeroDB._all.clear()


func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	real_time += dt
	match state:
		State.PLAYING:
			update_game(dt)
		State.CLEAR:
			update_clear(dt)
		State.DEAD:
			update_fx(dt)
			dead_timer -= dt
			if dead_timer <= 0.0:
				state = State.OVER
				ui.show_end(self, false)
		State.MENU:
			update_menu_fx(dt)
	update_camera(dt)
	for l in layers:
		l.queue_redraw()
	if state != State.MENU:
		ui.update_hud(self)
	var danger := 0.0
	if state == State.PLAYING and player.hp / player.stats.max_hp < 0.3:
		danger = 0.5 + 0.5 * sin(real_time * 6.0)
	vignette.material.set_shader_parameter("danger", danger)
	vignette.material.set_shader_parameter("slowmo", clampf(time_slow, 0.0, 1.0) if state == State.PLAYING else 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func get_move() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v == Vector2.ZERO:
		v = touch_move
	return v.limit_length(1.0)


func ability_down() -> bool:
	return Input.is_action_pressed("ability") or touch_ability


# ---------- Fluxo da partida ----------

func new_run(h: HeroBase) -> void:
	hero = h
	player.setup(h)
	player.visible = true
	kills = 0
	run_time = 0.0
	time = 0.0
	pending_levels = 0
	fx_under.clear()
	fx_top.clear()
	particles.clear()
	texts.clear()
	start_wave(1)


func start_wave(n: int) -> void:
	wave = n
	wave_time = 0.0
	wave_ended = false
	spawn_acc = 0.0
	elite_spawned = false
	is_boss_wave = Config.BOSS_WAVES.has(n)
	wave_duration = INF if is_boss_wave else minf(20.0 + (n - 1) * 5.0, 60.0)
	boss = null
	boss_defeated = false
	time_slow = 0.0
	enemies.clear()
	projectiles.clear()
	enemy_bullets.clear()
	pickups.clear()
	timers.clear()
	spawn_queue.clear()

	# Como no Brotato: a vida é restaurada no começo de cada onda
	var p := player
	p.buffs.clear()
	p.recalc()
	p.hp = p.stats.max_hp
	p.position = Config.ARENA / 2.0
	p.invuln = 1.0
	p.shield = 0.0
	p.reflect = 0.0
	p.stealth = 0.0
	p.ability_timer = 0.0
	for slot in p.weapons:
		slot.timer = randf_range(0.3, 0.7)
		slot.data.clear()
	camera.reset_smoothing()

	state = State.PLAYING
	ui.show_hud()
	ui.hide_boss_bar()
	if is_boss_wave:
		schedule(1.5, spawn_boss.bind(Config.BOSS_WAVES[n]))
		ui.banner("ONDA %d" % n, "A Calamidade despertou!" if n == Config.TOTAL_WAVES else "Um chefe se aproxima!")
		Sfx.play("boss")
	else:
		ui.banner("ONDA %d" % n, "Sobreviva por %d segundos" % int(wave_duration))
		Sfx.play("wave")


func end_wave() -> void:
	if wave_ended:
		return
	wave_ended = true
	for e in enemies:
		e.dead = true
		burst(e.pos, e.color, 5)
	enemies.clear()
	enemy_bullets.clear()
	spawn_queue.clear()
	timers.clear()
	time_slow = 0.0
	for pk in pickups:
		pk.magnet = true
	state = State.CLEAR
	clear_timer = 1.4
	player.moving = false
	if wave < Config.TOTAL_WAVES:
		ui.banner("ONDA CONCLUÍDA!", "%d de %d" % [wave, Config.TOTAL_WAVES])
	Sfx.play("wave")


func update_clear(dt: float) -> void:
	time += dt
	for pk in pickups:
		pk.update(dt, self)
	pickups = pickups.filter(func(pk): return not pk.dead)
	update_fx(dt)
	player.queue_redraw()
	clear_timer -= dt
	if clear_timer > 0.0:
		return
	for pk in pickups:
		collect(pk, true)
	pickups.clear()
	if wave >= Config.TOTAL_WAVES:
		state = State.VICTORY
		save_record()
		Sfx.play("victory")
		ui.show_end(self, true)
		return
	save_record()
	if pending_levels > 0:
		open_level_up()
	else:
		open_shop()


func open_level_up() -> void:
	state = State.LEVELUP
	touch_ability = false
	Sfx.play("levelup")
	ui.open_level_up(player.level - pending_levels + 1, ItemDB.roll_level_up_options(player, wave))


func apply_option(opt: Dictionary) -> void:
	match opt.kind:
		"stat":
			player.add_mods(opt.mods)
		"weapon":
			player.add_weapon(opt.weapon_id)
		"item":
			player.add_item(opt.item)


func choose_level_up(opt: Dictionary) -> void:
	if state != State.LEVELUP:
		return
	apply_option(opt)
	pending_levels -= 1
	if pending_levels > 0:
		open_level_up()
	elif wave_ended:
		open_shop()
	else:
		state = State.PLAYING
		ui.hide_screens()


func open_shop() -> void:
	state = State.SHOP
	shop_rerolls = 0
	shop_offers = ItemDB.roll_shop_offers(player, wave + 1)
	ui.open_shop(self)


func reroll_cost() -> int:
	return int(ceil(2.0 + wave * 0.8)) + shop_rerolls * 2


func buy(i: int) -> void:
	if state != State.SHOP or i < 0 or i >= shop_offers.size() or shop_offers[i] == null:
		return
	var offer: Dictionary = shop_offers[i]
	if floori(player.gold) < offer.price:
		Sfx.play("deny")
		return
	if offer.kind == "weapon" and player.get_weapon(offer.weapon_id) == null and player.weapons.size() >= Config.MAX_WEAPONS:
		Sfx.play("deny")
		return
	player.gold -= offer.price
	apply_option(offer)
	shop_offers[i] = null
	Sfx.play("buy")
	ui.open_shop(self)


func reroll() -> void:
	if state != State.SHOP:
		return
	var cost := reroll_cost()
	if floori(player.gold) < cost:
		Sfx.play("deny")
		return
	player.gold -= cost
	shop_rerolls += 1
	shop_offers = ItemDB.roll_shop_offers(player, wave + 1)
	Sfx.play("buy")
	ui.open_shop(self)


func next_wave() -> void:
	if state != State.SHOP:
		return
	ui.hide_screens()
	start_wave(wave + 1)


func toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		touch_ability = false
		ui.show_pause(self)
	elif state == State.PAUSED:
		state = State.PLAYING
		ui.hide_screens()


func quit_to_menu() -> void:
	save_record()
	state = State.MENU
	player.visible = false
	enemies.clear()
	projectiles.clear()
	enemy_bullets.clear()
	pickups.clear()
	timers.clear()
	spawn_queue.clear()
	fx_under.clear()
	fx_top.clear()
	texts.clear()
	ui.show_menu()


func on_player_death() -> void:
	var p := player
	if p.revives > 0:
		p.revives -= 1
		p.hp = p.stats.max_hp * 0.5
		p.invuln = 2.5
		p.shield = 2.5
		damage_area(p.position, 260.0, 80.0 * ability_scale(), {"knockback": 800.0})
		add_fx(Fx.Ring.new(p.position, 260.0, Color("ff9f1a"), 0.6, 10.0))
		burst(p.position, Color("ff9f1a"), 40, 300.0)
		add_text(p.position + Vector2(0, -40), "RENASCEU!", Color("ff9f1a"), 34, true)
		ui.toast("A Pena de Fênix te trouxe de volta!")
		return
	p.hp = 0.0
	state = State.DEAD
	dead_timer = 1.5
	player.visible = false
	burst(p.position, p.hero.color, 50, 320.0)
	shake(14.0)
	Sfx.play("death")
	save_record()


# ---------- Recordes ----------

func load_records() -> Dictionary:
	var cfg := ConfigFile.new()
	var out := {}
	if cfg.load(Config.SAVE_PATH) == OK and cfg.has_section("records"):
		for k in cfg.get_section_keys("records"):
			out[k] = cfg.get_value("records", k)
	return out


func save_record() -> void:
	if hero == null:
		return
	var cfg := ConfigFile.new()
	cfg.load(Config.SAVE_PATH)
	var reached := Config.TOTAL_WAVES + 1 if state == State.VICTORY else wave
	if int(cfg.get_value("records", hero.id, 0)) < reached:
		cfg.set_value("records", hero.id, reached)
		cfg.save(Config.SAVE_PATH)


# ---------- Dificuldade ----------

static func hp_scale(w: int) -> float:
	return 1.0 + (w - 1) * 0.22 + pow(w - 1, 2) * 0.018


static func dmg_scale(w: int) -> float:
	return 1.0 + (w - 1) * 0.09


func ability_scale() -> float:
	return 1.0 + (wave - 1) * 0.15


# ---------- Atualização principal ----------

func update_game(dt: float) -> void:
	time += dt
	run_time += dt
	wave_time += dt
	time_slow = maxf(0.0, time_slow - dt)
	var edt := dt * (0.25 if time_slow > 0.0 else 1.0)  # tempo dos inimigos

	grid.clear()
	for e in enemies:
		if not e.dead:
			grid.insert(e)

	if not timers.is_empty():
		var due := []
		for t in timers:
			t.at -= dt
			if t.at <= 0.0:
				due.append(t)
		if not due.is_empty():
			timers = timers.filter(func(t): return t.at > 0.0)
			for t in due:
				t.fn.call()

	var p := player
	p.update(dt, self)
	if time_slow > 0.0 and p.moving:
		afterimage_t -= dt
		if afterimage_t <= 0.0:
			afterimage_t = 0.05
			add_fx(Fx.Afterimage.new(p.position, p.hero, p.facing, 0.3))

	update_spawning(dt)
	for e in enemies:
		if not e.dead:
			e.update(edt, self)
	separate_enemies()

	# contato inimigo → jogador (congelados não ferem)
	for e: Enemy in enemies:
		if e.dead or e.freeze_t > 0.0:
			continue
		var rr := e.r + p.r - 4.0
		if e.pos.distance_squared_to(p.position) < rr * rr:
			p.take_damage(e.damage, self)

	# projéteis do jogador
	for pr: Projectile in projectiles:
		pr.update(dt, self)
		if pr.dead:
			continue
		for e: Enemy in query(pr.pos, pr.r + 70.0):
			if pr.dead:
				break
			if e.dead or pr.hit.has(e):
				continue
			var rr := pr.r + e.r
			if pr.pos.distance_squared_to(e.pos) <= rr * rr:
				projectile_hit(pr, e)

	# projéteis inimigos (podem ser refletidos pelos braceletes)
	for b: Projectile in enemy_bullets:
		b.life -= edt
		b.pos += b.vel * edt
		if b.life <= 0.0 or not Rect2(Vector2(-20, -20), Config.ARENA + Vector2(40, 40)).has_point(b.pos):
			b.dead = true
			continue
		var d2 := b.pos.distance_squared_to(p.position)
		if p.reflect > 0.0 and d2 < pow(p.r * 2.2 + b.r, 2):
			b.dead = true
			reflect_bullet(b)
		elif d2 < pow(b.r + p.r - 3.0, 2):
			b.dead = true
			p.take_damage(b.damage, self)

	for pk in pickups:
		pk.update(dt, self)
	update_fx(dt)

	enemies = enemies.filter(func(e): return not e.dead)
	projectiles = projectiles.filter(func(pr): return not pr.dead)
	enemy_bullets = enemy_bullets.filter(func(b): return not b.dead)
	pickups = pickups.filter(func(pk): return not pk.dead)

	if state != State.PLAYING:
		return
	if not is_boss_wave and wave_time >= wave_duration:
		end_wave()
	elif pending_levels > 0:
		open_level_up()


func reflect_bullet(b: Projectile) -> void:
	var t := nearest_enemy(b.pos, 600.0)
	var dir := (t.pos - b.pos).normalized() if t else -b.vel.normalized()
	add_projectile({"kind": "shard", "pos": b.pos, "vel": dir * 650.0, "r": 6.0, "damage": 20.0 * ability_scale(), "life": 1.2, "color": Config.C_GOLD})
	particle(b.pos, Vector2.ZERO, 0.2, Config.C_GOLD, 8.0)


func update_fx(dt: float) -> void:
	fx_under = fx_under.filter(func(f): return f.update(dt))
	fx_top = fx_top.filter(func(f): return f.update(dt))
	texts = texts.filter(func(f): return f.update(dt))
	var damp := pow(0.94, dt * 60.0)
	for pt in particles:
		pt.life -= dt
		pt.pos += pt.vel * dt
		pt.vel *= damp
	particles = particles.filter(func(pt): return pt.life > 0.0)
	if not spawn_queue.is_empty():
		var ready := []
		for s in spawn_queue:
			s.t -= dt
			if s.t <= 0.0:
				ready.append(s)
		if not ready.is_empty():
			spawn_queue = spawn_queue.filter(func(s): return s.t > 0.0)
			for s in ready:
				enemies.append(Enemy.new().setup(EnemyDB.TYPES[s.type], s.pos, wave, s.elite))


func update_menu_fx(dt: float) -> void:
	if randf() < dt * 30.0:
		var view := get_viewport_rect().size / camera.zoom
		var top_left := camera.get_screen_center_position() - view / 2.0
		particle(top_left + Vector2(randf() * view.x, view.y + 10.0), Vector2(randf_range(-15, 15), randf_range(-90, -40)),
			randf_range(3.0, 6.0), Config.C_EMBER if randf() < 0.7 else Config.C_GOLD, randf_range(2.0, 4.0))
	update_fx(dt)


func update_camera(dt: float) -> void:
	var vs := get_viewport_rect().size
	var z := clampf(minf(vs.x, vs.y) / 680.0, 0.6, 1.4)
	camera.zoom = Vector2(z, z)
	if state == State.MENU:
		camera.position = Config.ARENA / 2.0 + Vector2(sin(real_time * 0.12) * 260.0, cos(real_time * 0.09) * 160.0)
	else:
		camera.position = player.position
	if shake_amt > 0.2:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt
		shake_amt *= exp(-dt * 12.0)
	else:
		shake_amt = 0.0
		camera.offset = Vector2.ZERO


# ---------- Spawn ----------

func update_spawning(dt: float) -> void:
	if is_boss_wave and (boss_defeated or boss == null):
		return
	var ramp := 0.7 + 0.6 * minf(1.0, wave_time / minf(wave_duration, 60.0))
	var rate := (0.9 + wave * 0.38) * ramp
	if is_boss_wave:
		rate *= 0.45
	spawn_acc += rate * dt
	while spawn_acc >= 1.0:
		var size := mini(floori(spawn_acc), randi_range(1, 1 + wave / 4))
		spawn_acc -= size
		queue_group(size)
	# elite com baú a cada 3 ondas
	if not is_boss_wave and wave % 3 == 0 and not elite_spawned and wave_time > wave_duration * 0.35:
		elite_spawned = true
		queue_group(1, true)


func random_spawn_point() -> Vector2:
	var p := Vector2.ZERO
	for i in 14:
		p = Vector2(randf_range(60, Config.ARENA.x - 60), randf_range(60, Config.ARENA.y - 60))
		if p.distance_to(player.position) > 300.0:
			break
	return p


func queue_group(size: int, elite: bool = false, type: String = "", at = null) -> void:
	if enemies.size() + spawn_queue.size() >= Config.MAX_ENEMIES:
		return
	var t := type if type != "" else EnemyDB.pick_type(wave)
	var base: Vector2 = at if at != null else random_spawn_point()
	for i in size:
		var off := Vector2(randf_range(-45, 45), randf_range(-45, 45)) if size > 1 else Vector2.ZERO
		spawn_queue.append({"pos": (base + off).clamp(Vector2(30, 30), Config.ARENA - Vector2(30, 30)), "type": t, "elite": elite, "t": 0.9})


func spawn_boss(key: String) -> void:
	var d: Dictionary = EnemyDB.BOSSES[key]
	var y := 220.0 if player.position.y > Config.ARENA.y / 2.0 else Config.ARENA.y - 220.0
	boss = Boss.new().setup_boss(d, Vector2(Config.ARENA.x / 2.0, y))
	enemies.append(boss)
	add_fx(Fx.Ring.new(boss.pos, 220.0, Color("ff3d2e"), 0.8, 12.0))
	burst(boss.pos, Color("ff3d2e"), 40, 300.0)
	shake(12.0)
	ui.show_boss_bar(d.name)


func separate_enemies() -> void:
	for e in enemies:
		if e.dead or e.boss or e.def.behavior == "phase":
			continue
		for o in query(e.pos, e.r + 64.0):
			if o == e or o.dead or o.def.behavior == "phase":
				continue
			var delta: Vector2 = e.pos - o.pos
			var min_d: float = e.r + o.r
			var d2 := delta.length_squared()
			if d2 < min_d * min_d and d2 > 0.0001:
				var d := sqrt(d2)
				e.pos += delta / d * (min_d - d) * (1.0 if o.boss else 0.5)


# ---------- Combate ----------

func query(pos: Vector2, r: float) -> Array:
	return grid.query(pos, r, [])


## opts: knockback, dir (Vector2), slow, slow_time, freeze, root, no_crit
func hit_enemy(e: Enemy, base: float, opts: Dictionary = {}) -> float:
	if e.dead:
		return 0.0
	var p := player
	var crit: bool = not opts.get("no_crit", false) and randf() < p.stats.crit
	var dmg: float = base * p.stats.damage * (p.stats.crit_mult if crit else 1.0)
	dmg = maxf(1.0, roundf(dmg * randf_range(0.9, 1.1)))
	e.hp -= dmg
	e.flash = 0.08
	if opts.get("knockback", 0.0) != 0.0:
		var dir: Vector2 = opts.get("dir", (e.pos - p.position).normalized())
		e.kb += dir * opts.knockback * (1.0 - e.kb_resist)
	if opts.has("slow"):
		e.apply_slow(opts.slow, opts.get("slow_time", 1.0))
	if opts.has("freeze"):
		e.apply_freeze(opts.freeze)
	if opts.has("root"):
		e.apply_root(opts.root)
	add_text(e.pos + Vector2(0, -e.r), str(int(dmg)), Config.C_GOLD if crit else Color.WHITE, 22 if crit else 16)
	if crit and randf() < 0.12:
		add_text(e.pos + Vector2(randf_range(-20, 20), -e.r - 26), ["POW!", "BAM!", "ZAP!", "KRAK!", "WHAM!"].pick_random(), Color("ffd23f"), 30, true)
	if p.stats.lifesteal > 0.0 and randf() < p.stats.lifesteal:
		p.heal(1.0)
	Sfx.play("hit")
	if e.hp <= 0.0:
		kill_enemy(e)
	return dmg


func damage_area(pos: Vector2, r: float, dmg: float, opts: Dictionary = {}) -> int:
	var n := 0
	for e in query(pos, r + 70.0):
		if e.dead:
			continue
		var rr: float = r + e.r
		if pos.distance_squared_to(e.pos) <= rr * rr:
			var o := opts.duplicate()
			o["dir"] = (e.pos - pos).normalized()
			hit_enemy(e, dmg, o)
			n += 1
	return n


func cone_damage(pos: Vector2, reach: float, angle: float, arc: float, dmg: float, opts: Dictionary = {}) -> void:
	for e: Enemy in enemies.duplicate():
		if e.dead:
			continue
		var to := e.pos - pos
		var d := to.length() - e.r
		if d > reach:
			continue
		if d < 20.0 or absf(U.norm_angle(to.angle() - angle)) <= arc / 2.0:
			var o := opts.duplicate()
			o["dir"] = to.normalized()
			hit_enemy(e, dmg, o)


func line_damage(a: Vector2, b: Vector2, width: float, dmg: float, opts: Dictionary = {}) -> int:
	var n := 0
	var dir := (b - a).normalized()
	for e: Enemy in enemies.duplicate():
		if e.dead:
			continue
		if U.dist_to_segment(e.pos, a, b) < width + e.r:
			var o := opts.duplicate()
			o["dir"] = dir
			hit_enemy(e, dmg, o)
			n += 1
	return n


func projectile_hit(pr: Projectile, e: Enemy) -> void:
	pr.hit[e] = true
	if pr.explode > 0.0:
		damage_area(pr.pos, pr.explode, pr.damage, {"knockback": 180.0})
		explosion(pr.pos, pr.explode, pr.color)
		pr.dead = true
		return
	var opts := {"knockback": pr.knockback, "dir": pr.vel.normalized()}
	if pr.slow > 0.0:
		opts["slow"] = pr.slow
		opts["slow_time"] = pr.slow_time
	hit_enemy(e, pr.damage, opts)
	if pr.bounces > 0:
		var next := nearest_enemy(pr.pos, 260.0, pr.hit)
		if next:
			pr.bounces -= 1
			pr.vel = (next.pos - pr.pos).normalized() * pr.vel.length()
			pr.life = maxf(pr.life, 0.8)
			return
	if pr.pierce > 0:
		pr.pierce -= 1
		return
	pr.dead = true


func kill_enemy(e: Enemy) -> void:
	if e.dead:
		return
	e.dead = true
	kills += 1
	burst(e.pos, e.color, 80 if e.boss else 8)
	Sfx.play("kill")
	if e.boss:
		boss_defeated = true
		boss = null
		ui.hide_boss_bar()
		explosion(e.pos, 200.0, Config.C_EMBER)
		add_text(e.pos + Vector2(0, -60), "KABOOM!", Color("ffd23f"), 56, true)
		shake(18.0)
		for i in 30:
			pickups.append(Pickup.make("gem", e.pos + Vector2(randf_range(-60, 60), randf_range(-60, 60)), maxi(1, e.xp / 10), 2))
		if wave < Config.TOTAL_WAVES:
			pickups.append(Pickup.make("chest", e.pos))
		for o in enemies:
			if not o.dead and not o.boss:
				kill_enemy(o)
		schedule(1.6, end_wave)
		return
	if e.elite:
		for i in 6:
			pickups.append(Pickup.make("gem", e.pos, roundi(e.xp / 6.0), 2))
		pickups.append(Pickup.make("chest", e.pos))
		add_text(e.pos + Vector2(0, -40), "KABOOM!", Color("ffd23f"), 40, true)
	else:
		drop_gem(e.pos, e.xp, 1)
	if randf() < 0.012 + player.stats.luck * 0.0004:
		pickups.append(Pickup.make("heart", e.pos))


func drop_gem(pos: Vector2, value: int, gold: int) -> void:
	# Muitas gemas no chão: junta o valor numa gema existente para poupar desempenho
	if pickups.size() > 320:
		var g: Pickup = pickups.pick_random()
		if g.kind == "gem":
			g.value += value
			g.gold += gold
			return
	pickups.append(Pickup.make("gem", pos, value, gold))


func collect(pk: Pickup, silent: bool = false) -> void:
	var p := player
	match pk.kind:
		"gem":
			gain_xp(pk.value)
			p.gold += pk.gold * p.stats.gold_gain
			if not silent:
				Sfx.play("pickup")
		"heart":
			p.heal(p.stats.max_hp * 0.2)
		"chest":
			var item := ItemDB.roll_chest_item(p, wave)
			p.add_item(item)
			ui.toast("Baú: %s" % item.name)
			add_text(p.position + Vector2(0, -40), item.name, Config.C_GOLD, 22)
			Sfx.play("chest")


func gain_xp(v: float) -> void:
	var p := player
	p.xp += v * p.stats.xp_gain
	var need := p.xp_to_next()
	while p.xp >= need:
		p.xp -= need
		p.level += 1
		pending_levels += 1
		need = p.xp_to_next()


# ---------- Consultas e criação ----------

## O chefe conta como 150px mais perto, para as armas priorizarem ele
func nearest_enemy(pos: Vector2, max_r: float, exclude: Dictionary = {}) -> Enemy:
	var best: Enemy = null
	var best_d := max_r * max_r
	for e in enemies:
		if e.dead or exclude.has(e):
			continue
		var d := pos.distance_squared_to(e.pos)
		if e.boss:
			d = pow(maxf(0.0, sqrt(d) - 150.0), 2)
		if d < best_d:
			best_d = d
			best = e
	return best


func random_enemy(pos: Vector2, max_r: float, exclude: Dictionary = {}) -> Enemy:
	var r2 := max_r * max_r
	var list := enemies.filter(func(e): return not e.dead and not exclude.has(e) and pos.distance_squared_to(e.pos) < r2)
	return list.pick_random() if not list.is_empty() else null


func add_projectile(o: Dictionary) -> Projectile:
	var pr := Projectile.make(o)
	projectiles.append(pr)
	return pr


func add_fx(f) -> void:
	if f.under:
		fx_under.append(f)
	else:
		fx_top.append(f)


func schedule(delay: float, fn: Callable) -> void:
	timers.append({"at": delay, "fn": fn})


func add_text(pos: Vector2, text: String, color: Color, size: int, comic: bool = false) -> void:
	if texts.size() > 80:
		texts.pop_front()
	texts.append(Fx.FloatText.new(pos, text, color, size, comic))


func enemy_shoot(pos: Vector2, angle: float, speed: float, dmg: float, color: Color) -> void:
	var b := Projectile.new()
	b.hostile = true
	b.pos = pos
	b.vel = Vector2.from_angle(angle) * speed
	b.r = 7.0
	b.damage = dmg
	b.life = 5.0
	b.color = color
	enemy_bullets.append(b)


func particle(pos: Vector2, vel: Vector2, life: float, color: Color, size: float) -> void:
	if particles.size() > 600:
		return
	var pt := Fx.Particle.new()
	pt.pos = pos
	pt.vel = vel
	pt.life = life
	pt.max_life = life
	pt.color = color
	pt.size = size
	particles.append(pt)


func burst(pos: Vector2, color: Color, n: int = 8, speed: float = 170.0) -> void:
	for i in n:
		particle(pos, Vector2.from_angle(randf() * TAU) * randf_range(speed * 0.3, speed), randf_range(0.25, 0.6), color, randf_range(3.0, 6.0))


func explosion(pos: Vector2, r: float, color: Color) -> void:
	add_fx(Fx.Explosion.new(pos, r, color))
	burst(pos, color, 10, r * 3.0)
	Sfx.play("explode")


func shake(a: float) -> void:
	shake_amt = maxf(shake_amt, a)
