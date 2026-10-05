extends Node
## Simulação automática: um bot joga as 20 ondas com cada herói em "modo deus"
## (a vida nunca acaba) e mostra um resumo. Útil para achar erros e ajustar o balanceamento.
##
## Rode no terminal:
##   godot --headless --path . res://tests/simulate.tscn
## Para um herói só:
##   godot --headless --path . res://tests/simulate.tscn -- solar_titan

const DT := 1.0 / 30.0

var game: Game


func _ready() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var only := OS.get_cmdline_user_args()
	var t0 := Time.get_ticks_msec()
	print("herói               | resultado | onda | nível | abates | armas | itens | chefe10 | chefe20 | dano recebido (x vida máx) nas ondas 1/5/10/15/20")
	for hero in HeroDB.all():
		if not only.is_empty() and not only.has(hero.id):
			continue
		print(_run(hero))
	print("tempo total: %.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	get_tree().quit()


func _run(hero: HeroBase) -> String:
	game.ui.hide_screens()
	game.new_run(hero)
	var p := game.player
	var boss_t := {}
	var hurt := {}
	var frames := 0
	while frames < 120000:
		frames += 1
		match game.state:
			Game.State.PLAYING:
				p.hp = p.stats.max_hp
				_steer(frames)
				game.touch_ability = frames % 50 == 0
				game.update_game(DT)
				if p.hp < p.stats.max_hp:
					hurt[game.wave] = hurt.get(game.wave, 0.0) + (p.stats.max_hp - p.hp) / p.stats.max_hp
				if game.boss:
					boss_t[game.wave] = boss_t.get(game.wave, 0.0) + DT
				if frames % 90 == 0:
					game.ui.update_hud(game)
			Game.State.CLEAR:
				game.update_clear(DT)
			Game.State.LEVELUP:
				game.choose_level_up(game.ui.level_options[0])
			Game.State.SHOP:
				for i in 4:
					game.buy(i)
				game.next_wave()
			_:
				break
	var result := "VITÓRIA" if game.state == Game.State.VICTORY else str(Game.State.keys()[game.state])
	var weapons := ",".join(PackedStringArray(p.weapons.map(func(s): return "%s%d" % [s.w.id.substr(0, 6), s.level])))
	var hurt_txt := " ".join(PackedStringArray([1, 5, 10, 15, 20].map(func(w): return "%.1f" % hurt.get(w, 0.0))))
	return "%-19s | %-9s | %4d | %5d | %6d | %s | %d | %5ds | %5ds | %s" % [hero.id, result, game.wave, p.level, game.kills,
		weapons, p.items.size(), int(boss_t.get(10, 0.0)), int(boss_t.get(20, 0.0)), hurt_txt]


## Anda em quadrado; nas lutas de chefe, circula o chefe a ~260px (como um jogador faria)
func _steer(frames: int) -> void:
	var p := game.player
	if game.boss:
		var to := p.position - game.boss.pos
		var d := maxf(to.length(), 1.0)
		var m := Vector2(-to.y, to.x) / d
		if d > 300.0:
			m -= to / d
		elif d < 220.0:
			m += to / d
		game.touch_move = m.normalized()
	else:
		game.touch_move = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP][(frames / 90) % 4]
