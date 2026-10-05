class_name Player
extends Node2D
## O herói controlado pelo jogador.

## Atributos base. Heróis, itens e níveis somam modificadores a estes valores.
const BASE_STATS := {
	"max_hp": 100.0,
	"regen": 0.0,         # vida por segundo
	"armor": 0.0,         # reduz o dano recebido
	"speed": 1.0,         # multiplicador de movimento
	"damage": 1.0,        # multiplicador de dano
	"attack_speed": 1.0,  # multiplicador de velocidade de ataque
	"crit": 0.05,         # chance de crítico
	"crit_mult": 1.75,
	"area": 1.0,          # multiplicador de área
	"projectiles": 0.0,   # projéteis extras
	"pickup_range": 90.0, # alcance do ímã
	"dodge": 0.0,         # chance de esquiva
	"lifesteal": 0.0,     # chance de curar 1 ao acertar
	"cooldown": 1.0,      # multiplicador da recarga da habilidade
	"xp_gain": 1.0,
	"gold_gain": 1.0,
	"luck": 0.0,
}

var hero: HeroBase
var r := 17.0
var mods: Array = []
var buffs: Array = []
var items: Array = []
var weapons: Array = []
var stats: Dictionary = BASE_STATS.duplicate()
var hp := 100.0
var level := 1
var xp := 0.0
var gold := 0.0
var invuln := 0.0
var hurt_flash := 0.0
var shield := 0.0
var reflect := 0.0
var stealth := 0.0
var facing := 1.0
var dir := Vector2.RIGHT
var moving := false
var ability_timer := 0.0
var revives := 0
var anim_t := 0.0


func setup(h: HeroBase) -> void:
	hero = h
	mods = [h.mods]
	buffs = []
	items = []
	weapons = []
	level = 1
	xp = 0.0
	gold = 0.0
	revives = 0
	stats = BASE_STATS.duplicate()
	recalc()
	hp = stats.max_hp
	add_weapon(h.start_weapon)


func recalc() -> void:
	var s := BASE_STATS.duplicate()
	for m in mods:
		for k in m:
			s[k] = s.get(k, 0.0) + m[k]
	for b in buffs:
		for k in b.mods:
			s[k] = s.get(k, 0.0) + b.mods[k]
	s.max_hp = maxf(1.0, roundf(s.max_hp))
	s.speed = maxf(0.4, s.speed)
	s.damage = maxf(0.1, s.damage)
	s.attack_speed = maxf(0.3, s.attack_speed)
	s.crit = clampf(s.crit, 0.0, 1.0)
	s.area = maxf(0.3, s.area)
	s.projectiles = maxf(0.0, roundf(s.projectiles))
	s.pickup_range = maxf(30.0, s.pickup_range)
	s.dodge = clampf(s.dodge, 0.0, 0.6)
	s.lifesteal = clampf(s.lifesteal, 0.0, 0.5)
	s.cooldown = maxf(0.3, s.cooldown)
	s.xp_gain = maxf(0.1, s.xp_gain)
	s.gold_gain = maxf(0.1, s.gold_gain)
	var prev_max: float = stats.max_hp
	stats = s
	if s.max_hp > prev_max:
		hp += s.max_hp - prev_max
	hp = minf(hp, s.max_hp)


func add_mods(m: Dictionary) -> void:
	mods.append(m)
	recalc()


func add_buff(id: String, m: Dictionary, duration: float) -> void:
	buffs = buffs.filter(func(b): return b.id != id)
	buffs.append({"id": id, "mods": m, "time": duration})
	recalc()


func has_buff(id: String) -> bool:
	for b in buffs:
		if b.id == id:
			return true
	return false


func get_weapon(id: String) -> WeaponSlot:
	for w in weapons:
		if w.w.id == id:
			return w
	return null


func add_weapon(id: String) -> WeaponSlot:
	var existing := get_weapon(id)
	if existing:
		existing.level = mini(existing.level + 1, existing.w.max_level)
		return existing
	if weapons.size() >= Config.MAX_WEAPONS:
		return null
	var slot := WeaponSlot.new(WeaponDB.get_weapon(id))
	weapons.append(slot)
	return slot


func add_item(item: Dictionary) -> void:
	items.append(item)
	if item.get("special", "") == "revive":
		revives += 1
	add_mods(item.mods)


func xp_to_next() -> float:
	return roundf(pow(level + 3, 2) * 0.8)


func ability_cooldown() -> float:
	return hero.ability_cooldown * stats.cooldown


func update(dt: float, game: Game) -> void:
	var mv := game.get_move()
	moving = mv.length_squared() > 0.0001
	if moving:
		dir = mv.normalized()
		if absf(mv.x) > 0.15:
			facing = signf(mv.x)
	var sp: float = Config.BASE_MOVE_SPEED * stats.speed
	position += mv * sp * dt
	position = position.clamp(Vector2(r, r), Config.ARENA - Vector2(r, r))
	anim_t += dt

	if stats.regen > 0.0:
		heal(stats.regen * dt, true)

	if not buffs.is_empty():
		var expired := false
		for b in buffs:
			b.time -= dt
			if b.time <= 0.0:
				expired = true
		if expired:
			buffs = buffs.filter(func(b): return b.time > 0.0)
			recalc()

	invuln = maxf(0.0, invuln - dt)
	shield = maxf(0.0, shield - dt)
	reflect = maxf(0.0, reflect - dt)
	stealth = maxf(0.0, stealth - dt)
	hurt_flash = maxf(0.0, hurt_flash - dt)
	ability_timer = maxf(0.0, ability_timer - dt)

	if ability_timer <= 0.0 and game.ability_down():
		hero.cast(game, self)
		ability_timer = ability_cooldown()
		Sfx.play("ability")

	for slot in weapons:
		var s: Dictionary = slot.stats()
		slot.w.update(game, self, slot, s, dt)
		if slot.w.uses_cooldown:
			slot.timer -= dt * stats.attack_speed
			if slot.timer <= 0.0:
				slot.timer = s.cooldown if slot.w.fire(game, self, slot, s) else 0.1
	queue_redraw()


func take_damage(amount: float, game: Game) -> bool:
	if invuln > 0.0 or game.state != Game.State.PLAYING:
		return false
	if randf() < stats.dodge:
		game.add_text(position + Vector2(0, -26), "Esquiva!", Color("9fd8ff"), 17)
		invuln = 0.25
		return false
	var a: float = stats.armor
	var factor := 15.0 / (15.0 + a) if a >= 0.0 else 1.0 + -a / 15.0
	var dmg := maxf(1.0, roundf(amount * factor))
	hp -= dmg
	invuln = 0.45
	hurt_flash = 0.2
	game.add_text(position + Vector2(0, -28), "-%d" % dmg, Color("ff5d5d"), 22)
	game.shake(5.0)
	Sfx.play("hurt")
	if hp <= 0.0:
		game.on_player_death()
	return true


func heal(amount: float, silent: bool = false) -> void:
	if hp >= stats.max_hp or amount <= 0.0:
		return
	var before := hp
	hp = minf(stats.max_hp, hp + amount)
	var gained := roundf(hp - before)
	if not silent and gained >= 1.0:
		Game.I.add_text(position + Vector2(0, -30), "+%d" % gained, Config.C_GOOD, 18)


func _draw() -> void:
	if hero == null:
		return
	var t := anim_t
	for slot in weapons:
		slot.w.draw_under(self, self, slot, slot.stats())
	if has_buff("rage"):
		U.disc(self, Vector2.ZERO, r * 1.9 + sin(t * 14.0) * 3.0, Color(1, 0.25, 0.25, 0.22))
	var blink := invuln > 0.0 and shield <= 0.0 and int(t * 14.0) % 2 == 0
	var alpha := 0.45 if blink else 1.0
	if stealth > 0.0:
		alpha = 0.35
	hero.draw_body(self, Vector2.ZERO, r, facing, t, {"moving": moving, "flash": hurt_flash > 0.0, "alpha": alpha})
	for slot in weapons:
		slot.w.draw_over(self, self, slot, slot.stats())
	if shield > 0.0:
		var a := minf(1.0, shield) * 0.8
		U.disc(self, Vector2.ZERO, r * 1.75 + sin(t * 8.0) * 1.5, Color(0.6, 0.75, 1.0, a * 0.2), Color(0.8, 0.88, 1.0, a), 3.0)
	if reflect > 0.0:
		var a2 := minf(1.0, reflect)
		for i in 2:
			var ang := t * 6.0 + PI * i
			draw_arc(Vector2.ZERO, r * 2.1, ang, ang + 1.2, 10, Color(Config.C_GOLD, a2), 4.0, true)
