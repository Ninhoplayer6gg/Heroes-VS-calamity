class_name GameUI
extends Control
## Toda a interface: menu de heróis, HUD, subir de nível, loja, pausa e fim de jogo.
## É montada em código para ficar fácil de ler e ajustar num lugar só.

const FONT_COMIC := preload("res://assets/fonts/Bangers-Regular.ttf")
const FONT_SEMI := preload("res://assets/fonts/BarlowSemiCondensed-SemiBold.ttf")
const FONT_BOLD := preload("res://assets/fonts/BarlowSemiCondensed-Bold.ttf")

var game: Game
var selected_hero: HeroBase

# HUD
var hud: Control
var hp_bar: ProgressBar
var hp_label: Label
var xp_bar: ProgressBar
var lvl_label: Label
var gold_label: Label
var wave_label: Label
var timer_label: Label
var boss_box: VBoxContainer
var boss_name: Label
var boss_bar: ProgressBar
var slots_box: HBoxContainer
var slot_sig := ""
var ability_btn: AbilityButton
var pause_btn: Button
var touch_pad: TouchPad
var banner_box: VBoxContainer
var banner_title: Label
var banner_sub: Label
var banner_tween: Tween
var toasts: VBoxContainer

# Telas
var screens := {}
var hero_cards: Array = []
var detail_box: VBoxContainer
var start_btn: Button
var level_sub: Label
var level_cards: HBoxContainer
var level_options: Array = []
var level_lock_until := 0.0
var shop_title: Label
var shop_sub: Label
var shop_gold: Label
var shop_cards: HBoxContainer
var reroll_btn: Button
var next_btn: Button
var shop_weapons: VBoxContainer
var shop_items: HFlowContainer
var shop_stats: GridContainer
var pause_weapons: VBoxContainer
var pause_stats: GridContainer
var resume_btn: Button
var mute_btn: Button
var quit_btn: Button
var quit_armed := false
var end_title: Label
var end_sub: Label
var end_stats: GridContainer
var retry_btn: Button


func setup(g: Game) -> void:
	game = g
	theme = _make_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	_build_overlays()
	_build_menu()
	_build_level_up()
	_build_shop()
	_build_pause()
	_build_end()
	var last := ""
	var cfg := ConfigFile.new()
	if cfg.load(Config.SAVE_PATH) == OK:
		last = cfg.get_value("settings", "last_hero", "")
	var h := HeroDB.find(last)
	select_hero(h if h else HeroDB.all()[0])


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var n := -1
	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		n = event.keycode - KEY_1
	elif event.keycode >= KEY_KP_1 and event.keycode <= KEY_KP_4:
		n = event.keycode - KEY_KP_1
	match game.state:
		Game.State.LEVELUP:
			if n >= 0 and n < level_options.size():
				_choose_level(level_options[n])
				accept_event()
		Game.State.SHOP:
			if n >= 0:
				game.buy(n)
				accept_event()
			elif event.keycode == KEY_R:
				game.reroll()
				accept_event()


# ---------- Tema e peças ----------

func _box(bg: Color, border: Color, bw: int, radius: int, margin: float = 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.anti_aliasing = true
	return s


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = FONT_SEMI
	th.default_font_size = 20
	th.set_color("font_color", "Label", Config.C_BONE)
	th.set_stylebox("normal", "Button", _box(Config.C_PANEL_2, Config.C_LINE, 2, 6, 12))
	th.set_stylebox("hover", "Button", _box(Config.C_PANEL_2.lightened(0.06), Config.C_MIST, 2, 6, 12))
	th.set_stylebox("pressed", "Button", _box(Config.C_PANEL_2.darkened(0.15), Config.C_MIST, 2, 6, 12))
	th.set_stylebox("disabled", "Button", _box(Config.C_PANEL_2, Config.C_LINE, 2, 6, 12))
	var focus := _box(Color.TRANSPARENT, Config.C_GOLD, 3, 8)
	focus.draw_center = false
	focus.set_expand_margin_all(3)
	th.set_stylebox("focus", "Button", focus)
	th.set_font("font", "Button", FONT_BOLD)
	th.set_font_size("font_size", "Button", 22)
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		th.set_color(c, "Button", Config.C_BONE)
	th.set_stylebox("panel", "PanelContainer", _box(Color(Config.C_PANEL, 0.97), Config.C_LINE, 1, 12, 24))
	th.set_stylebox("background", "ProgressBar", _box(Color(0.04, 0.02, 0.05, 0.85), Color(0.02, 0.01, 0.03), 2, 4, 0))
	th.set_constant("separation", "VBoxContainer", 10)
	th.set_constant("separation", "HBoxContainer", 10)
	return th


func _label(text: String, size: int = 20, color: Color = Config.C_BONE, font: Font = null, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _comic(text: String, size: int, color: Color = Config.C_BONE, outline: int = 10) -> Label:
	var l := _label(text, size, color, FONT_COMIC, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", Config.C_INK)
	return l


func _wrap(l: Label, width: float) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width
	return l


func _primary(b: Button) -> Button:
	b.add_theme_stylebox_override("normal", _box(Config.C_EMBER, Color("5c1a0c"), 2, 6, 12))
	b.add_theme_stylebox_override("hover", _box(Config.C_EMBER.lightened(0.12), Config.C_GOLD, 2, 6, 12))
	b.add_theme_stylebox_override("pressed", _box(Config.C_EMBER.darkened(0.15), Color("5c1a0c"), 2, 6, 12))
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(c, Color("1a0805"))
	return b


func _button(text: String, on_press: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 52)
	b.pressed.connect(on_press)
	return _primary(b) if primary else b


func _icon(icon: String, color: Color, size: float) -> IconView:
	var v := IconView.new()
	v.icon = icon
	v.color = color
	v.custom_minimum_size = Vector2(size, size)
	return v


func _screen(key: String) -> PanelContainer:
	var s := Control.new()
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.visible = false
	add_child(s)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.04, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	screens[key] = s
	return panel


func _h3(text: String) -> Label:
	var l := _label(text.to_upper(), 15, Config.C_MIST, FONT_BOLD)
	return l


func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


# ---------- Telas: mostrar/esconder ----------

func show_screen(key: String) -> void:
	if banner_tween:
		banner_tween.kill()
	banner_box.modulate.a = 0.0
	for k in screens:
		screens[k].visible = k == key
	get_viewport().gui_release_focus()


func hide_screens() -> void:
	for k in screens:
		screens[k].visible = false
	get_viewport().gui_release_focus()


# ---------- Menu ----------

func _build_menu() -> void:
	var panel := _screen("menu")
	screens.menu.get_child(0).color = Color(0.03, 0.02, 0.04, 0.55)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_label("SOBREVIVA A 20 ONDAS E DERROTE A CALAMIDADE", 17, Config.C_EMBER, FONT_BOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var title := _comic("HEROES VS CALAMITY", 88, Config.C_BONE, 14)
	box.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	box.add_child(row)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	row.add_child(grid)
	for h in HeroDB.all():
		var card := Button.new()
		card.custom_minimum_size = Vector2(142, 156)
		card.toggle_mode = true
		var inner := VBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.add_theme_constant_override("separation", 0)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(inner)
		var portrait := IconView.new()
		portrait.hero = h
		portrait.custom_minimum_size = Vector2(130, 104)
		inner.add_child(portrait)
		var nm := _wrap(_label(h.name, 18, Config.C_BONE, FONT_BOLD, HORIZONTAL_ALIGNMENT_CENTER), 130)
		inner.add_child(nm)
		card.pressed.connect(select_hero.bind(h))
		grid.add_child(card)
		hero_cards.append({"hero": h, "button": card, "portrait": portrait})

	detail_box = VBoxContainer.new()
	detail_box.custom_minimum_size = Vector2(430, 0)
	detail_box.add_theme_constant_override("separation", 6)
	row.add_child(detail_box)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(actions)
	start_btn = _button("Jogar", _start_game, true)
	start_btn.custom_minimum_size = Vector2(360, 58)
	actions.add_child(start_btn)
	box.add_child(_label("WASD / setas: mover   ·   Espaço: habilidade   ·   Esc: pausa   ·   Controle e toque também funcionam", 16, Config.C_MIST, null, HORIZONTAL_ALIGNMENT_CENTER))


func select_hero(h: HeroBase) -> void:
	selected_hero = h
	for c in hero_cards:
		c.button.set_pressed_no_signal(c.hero == h)
		c.portrait.animate = c.hero == h
		var style := _box(Config.C_PANEL_2, Config.C_GOLD if c.hero == h else Config.C_LINE, 3 if c.hero == h else 2, 8, 6)
		for st in ["normal", "pressed", "hover", "hover_pressed"]:
			c.button.add_theme_stylebox_override(st, style)
	var cfg := ConfigFile.new()
	cfg.load(Config.SAVE_PATH)
	cfg.set_value("settings", "last_hero", h.id)
	cfg.save(Config.SAVE_PATH)
	_fill_detail(h)
	start_btn.text = "Jogar com %s" % h.name


func _fill_detail(h: HeroBase) -> void:
	_clear(detail_box)
	var name_l := _comic(h.name.to_upper(), 44, h.color.lightened(0.25), 8)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_box.add_child(name_l)
	detail_box.add_child(_label(h.title, 19, Config.C_GOLD, FONT_BOLD))
	detail_box.add_child(_wrap(_label(h.desc, 17, Config.C_MIST), 430))

	detail_box.add_child(_label("HABILIDADE  ·  ESPAÇO", 14, Config.C_EMBER, FONT_BOLD))
	var ab := HBoxContainer.new()
	ab.add_child(_icon(h.ability_icon, h.ability_color, 28))
	ab.add_child(_label("%s  (%ds)" % [h.ability_name, int(h.ability_cooldown)], 20, Config.C_BONE, FONT_BOLD))
	detail_box.add_child(ab)
	detail_box.add_child(_wrap(_label(h.ability_desc, 16, Config.C_MIST), 430))

	var w := WeaponDB.get_weapon(h.start_weapon)
	detail_box.add_child(_label("ARMA EXCLUSIVA", 14, Config.C_EMBER, FONT_BOLD))
	var wr := HBoxContainer.new()
	var wi := IconView.new()
	wi.weapon = w
	wi.custom_minimum_size = Vector2(28, 28)
	wr.add_child(wi)
	wr.add_child(_label(w.name, 20, Config.C_BONE, FONT_BOLD))
	detail_box.add_child(wr)
	detail_box.add_child(_wrap(_label(w.desc, 16, Config.C_MIST), 430))

	var mods := HFlowContainer.new()
	mods.add_theme_constant_override("h_separation", 14)
	for m in ItemDB.format_mods(h.mods):
		mods.add_child(_label(m.text, 17, Config.C_GOOD if m.good else Config.C_BAD, FONT_BOLD))
	detail_box.add_child(mods)

	var rec: int = game.load_records().get(h.id, 0)
	var rec_text := "Ainda não jogou com este herói"
	if rec > Config.TOTAL_WAVES:
		rec_text = "Recorde: derrotou A Calamidade!"
	elif rec > 0:
		rec_text = "Recorde: chegou à onda %d" % rec
	detail_box.add_child(_label(rec_text, 16, Config.C_GOLD))


func _start_game() -> void:
	if selected_hero == null:
		return
	hide_screens()
	game.new_run(selected_hero)


func show_menu() -> void:
	hud.visible = false
	hide_boss_bar()
	if selected_hero:
		select_hero(selected_hero)
	show_screen("menu")
	start_btn.grab_focus()


# ---------- HUD ----------

func _bar(size: Vector2, fill: Color) -> Array:
	var holder := Control.new()
	holder.custom_minimum_size = size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := ProgressBar.new()
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("fill", _box(fill, Color.TRANSPARENT, 0, 3, 0))
	holder.add_child(bar)
	var l := _label("", int(size.y * 0.7) + 2, Config.C_BONE, FONT_BOLD)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.offset_left = 8
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Config.C_INK)
	holder.add_child(l)
	return [holder, bar, l]


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	add_child(hud)

	touch_pad = TouchPad.new()
	touch_pad.ui = self
	touch_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(touch_pad)

	var left := VBoxContainer.new()
	left.position = Vector2(20, 16)
	left.add_theme_constant_override("separation", 6)
	hud.add_child(left)
	var hp := _bar(Vector2(280, 28), Config.C_HP)
	left.add_child(hp[0])
	hp_bar = hp[1]
	hp_label = hp[2]
	var xp := _bar(Vector2(280, 16), Config.C_XP)
	left.add_child(xp[0])
	xp_bar = xp[1]
	lvl_label = xp[2]
	var gold_row := HBoxContainer.new()
	gold_row.add_theme_constant_override("separation", 6)
	gold_row.add_child(_icon("coin", Config.C_GOLD, 26))
	gold_label = _comic("0", 30, Config.C_GOLD, 6)
	gold_row.add_child(gold_label)
	left.add_child(gold_row)

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.offset_top = 8
	top.add_theme_constant_override("separation", -6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	wave_label = _comic("ONDA 1", 32, Config.C_BONE, 8)
	top.add_child(wave_label)
	timer_label = _comic("20", 58, Config.C_BONE, 10)
	top.add_child(timer_label)
	boss_box = VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 2)
	boss_box.visible = false
	top.add_child(boss_box)
	boss_name = _comic("", 28, Color("ffb3a1"), 6)
	boss_box.add_child(boss_name)
	var bb := _bar(Vector2(560, 16), Color("e0402f"))
	boss_box.add_child(bb[0])
	boss_bar = bb[1]

	pause_btn = Button.new()
	pause_btn.text = "II"
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.custom_minimum_size = Vector2(52, 52)
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -72
	pause_btn.offset_top = 16
	pause_btn.offset_right = -20
	pause_btn.offset_bottom = 68
	pause_btn.pressed.connect(func(): game.toggle_pause())
	hud.add_child(pause_btn)

	slots_box = HBoxContainer.new()
	slots_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	slots_box.offset_left = 20
	slots_box.offset_top = -70
	slots_box.offset_bottom = -20
	slots_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	slots_box.add_theme_constant_override("separation", 8)
	slots_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(slots_box)

	ability_btn = AbilityButton.new()
	ability_btn.ui = self
	ability_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ability_btn.offset_left = -132
	ability_btn.offset_top = -132
	ability_btn.offset_right = -24
	ability_btn.offset_bottom = -24
	hud.add_child(ability_btn)


func show_hud() -> void:
	hud.visible = true
	slot_sig = ""


func update_hud(g: Game) -> void:
	var p := g.player
	hp_bar.value = p.hp / p.stats.max_hp
	hp_label.text = "%d / %d" % [maxi(0, ceili(p.hp)), int(p.stats.max_hp)]
	xp_bar.value = p.xp / p.xp_to_next()
	lvl_label.text = "Nível %d" % p.level
	gold_label.text = str(floori(p.gold))
	wave_label.text = "ONDA %d/%d" % [g.wave, Config.TOTAL_WAVES]
	if g.is_boss_wave:
		timer_label.text = "CHEFE" if g.boss else ("✓" if g.boss_defeated else "…")
		timer_label.add_theme_color_override("font_color", Color("ffb3a1"))
	else:
		var left := maxf(0.0, g.wave_duration - g.wave_time)
		timer_label.text = str(ceili(left))
		timer_label.add_theme_color_override("font_color", Config.C_EMBER if left <= 5.0 else Config.C_BONE)
	if g.boss:
		boss_bar.value = g.boss.hp / g.boss.max_hp
	ability_btn.queue_redraw()

	var sig := ""
	for s in p.weapons:
		sig += "%s%d|" % [s.w.id, s.level]
	if sig != slot_sig:
		slot_sig = sig
		_clear(slots_box)
		for i in Config.MAX_WEAPONS:
			var v := SlotView.new()
			v.slot = p.weapons[i] if i < p.weapons.size() else null
			v.custom_minimum_size = Vector2(50, 50)
			slots_box.add_child(v)


func show_boss_bar(boss_title: String) -> void:
	boss_name.text = boss_title.to_upper()
	boss_box.visible = true


func hide_boss_bar() -> void:
	boss_box.visible = false


func _build_overlays() -> void:
	banner_box = VBoxContainer.new()
	banner_box.set_anchors_preset(Control.PRESET_CENTER)
	banner_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner_box.offset_top = -170
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_box.modulate.a = 0.0
	add_child(banner_box)
	banner_title = _comic("", 110, Config.C_BONE, 18)
	banner_box.add_child(banner_title)
	banner_sub = _label("", 28, Config.C_GOLD, FONT_BOLD, HORIZONTAL_ALIGNMENT_CENTER)
	banner_sub.add_theme_constant_override("outline_size", 6)
	banner_sub.add_theme_color_override("font_outline_color", Config.C_INK)
	banner_box.add_child(banner_sub)

	toasts = VBoxContainer.new()
	toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toasts.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toasts.offset_top = 170
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toasts)


func banner(title: String, sub: String = "") -> void:
	banner_title.text = title
	banner_sub.text = sub
	if banner_tween:
		banner_tween.kill()
	banner_box.modulate.a = 0.0
	banner_tween = create_tween()
	banner_tween.tween_property(banner_box, "modulate:a", 1.0, 0.2)
	banner_tween.tween_interval(1.6)
	banner_tween.tween_property(banner_box, "modulate:a", 0.0, 0.5)


func toast(text: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(Color(Config.C_PANEL, 0.95), Config.C_GOLD, 1, 6, 10))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(_label(text, 20, Config.C_BONE, FONT_BOLD, HORIZONTAL_ALIGNMENT_CENTER))
	toasts.add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)


# ---------- Cartas ----------

func _card(opt: Dictionary, hotkey: int, price: int = -1, can_afford: bool = true) -> Button:
	var rarity: Dictionary = ItemDB.RARITIES[opt.rarity]
	var rc: Color = rarity.color
	var b := Button.new()
	b.custom_minimum_size = Vector2(196, 316) if price >= 0 else Vector2(250, 270)
	var bg := Config.C_PANEL_2.lerp(rc, 0.1)
	b.add_theme_stylebox_override("normal", _box(bg, rc, 2, 10, 12))
	b.add_theme_stylebox_override("hover", _box(bg.lightened(0.06), rc.lightened(0.2), 3, 10, 12))
	b.add_theme_stylebox_override("pressed", _box(bg.darkened(0.1), rc, 3, 10, 12))
	if price >= 0 and not can_afford:
		b.modulate = Color(1, 1, 1, 0.6)

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 12)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(box)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rl := _label(rarity.name.to_upper(), 14, rc, FONT_BOLD)
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(rl)
	top.add_child(_label("[%d]" % hotkey, 14, Config.C_MIST, FONT_BOLD))
	box.add_child(top)

	var icon := IconView.new()
	icon.custom_minimum_size = Vector2(0, 70)
	if opt.kind == "weapon":
		icon.weapon = WeaponDB.get_weapon(opt.weapon_id)
	else:
		icon.icon = opt.icon
		icon.color = opt.color
	box.add_child(icon)

	var inner_w := b.custom_minimum_size.x - 24
	box.add_child(_wrap(_label(opt.name, 21, Config.C_BONE, FONT_BOLD, HORIZONTAL_ALIGNMENT_CENTER), inner_w))
	box.add_child(_label(opt.tag, 15, Config.C_MIST, null, HORIZONTAL_ALIGNMENT_CENTER))
	for e in opt.effects:
		var col := Config.C_MIST if e.get("neutral", false) else (Config.C_GOOD if e.good else Config.C_BAD)
		box.add_child(_wrap(_label(e.text, 17, col, null if e.get("neutral", false) else FONT_BOLD, HORIZONTAL_ALIGNMENT_CENTER), inner_w))

	if price >= 0:
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(spacer)
		var pr := HBoxContainer.new()
		pr.alignment = BoxContainer.ALIGNMENT_CENTER
		pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pr.add_child(_icon("coin", Config.C_GOLD, 24))
		pr.add_child(_comic(str(price), 30, Config.C_GOLD if can_afford else Config.C_BAD, 6))
		box.add_child(pr)
	return b


# ---------- Subir de nível ----------

func _build_level_up() -> void:
	var panel := _screen("levelup")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(_comic("SUBIU DE NÍVEL!", 70, Config.C_GOLD, 12))
	level_sub = _label("", 20, Config.C_MIST, null, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(level_sub)
	level_cards = HBoxContainer.new()
	level_cards.add_theme_constant_override("separation", 14)
	level_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(level_cards)


func open_level_up(level: int, options: Array) -> void:
	show_screen("levelup")
	level_sub.text = "Nível %d. Escolha uma melhoria." % level
	level_options = options
	_clear(level_cards)
	for i in options.size():
		var c := _card(options[i], i + 1)
		c.pressed.connect(_choose_level.bind(options[i]))
		level_cards.add_child(c)
	level_lock_until = Time.get_ticks_msec() + 350
	# foco para controle (com atraso, para não escolher sem querer)
	get_tree().create_timer(0.5).timeout.connect(func():
		if game.state == Game.State.LEVELUP and level_cards.get_child_count() > 0 and get_viewport().gui_get_focus_owner() == null:
			level_cards.get_child(0).grab_focus()
	)


func _choose_level(opt: Dictionary) -> void:
	if Time.get_ticks_msec() < level_lock_until:
		return
	level_lock_until = Time.get_ticks_msec() + 250
	game.choose_level_up(opt)


# ---------- Loja ----------

func _build_shop() -> void:
	var panel := _screen("shop")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	titles.add_child(_label("LOJA DO MERCADOR", 16, Config.C_EMBER, FONT_BOLD))
	shop_title = _comic("", 52, Config.C_BONE, 10)
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titles.add_child(shop_title)
	shop_sub = _label("", 19, Config.C_MIST)
	titles.add_child(shop_sub)
	var gold_row := HBoxContainer.new()
	gold_row.add_child(_icon("coin", Config.C_GOLD, 40))
	shop_gold = _comic("0", 52, Config.C_GOLD, 10)
	gold_row.add_child(shop_gold)
	head.add_child(gold_row)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	box.add_child(body)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	body.add_child(main)
	shop_cards = HBoxContainer.new()
	shop_cards.add_theme_constant_override("separation", 12)
	main.add_child(shop_cards)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	main.add_child(actions)
	reroll_btn = _button("Trocar ofertas", func(): game.reroll())
	reroll_btn.custom_minimum_size = Vector2(260, 54)
	actions.add_child(reroll_btn)
	next_btn = _button("Próxima onda", func(): game.next_wave(), true)
	next_btn.custom_minimum_size = Vector2(260, 54)
	actions.add_child(next_btn)

	var side := PanelContainer.new()
	side.add_theme_stylebox_override("panel", _box(Color(0.04, 0.02, 0.05, 0.45), Config.C_LINE, 1, 8, 14))
	side.custom_minimum_size = Vector2(350, 0)
	body.add_child(side)
	var sbox := VBoxContainer.new()
	sbox.add_theme_constant_override("separation", 6)
	side.add_child(sbox)
	sbox.add_child(_h3("Armas"))
	shop_weapons = VBoxContainer.new()
	shop_weapons.add_theme_constant_override("separation", 2)
	sbox.add_child(shop_weapons)
	sbox.add_child(_h3("Itens"))
	shop_items = HFlowContainer.new()
	sbox.add_child(shop_items)
	sbox.add_child(_h3("Atributos"))
	shop_stats = GridContainer.new()
	shop_stats.columns = 4
	shop_stats.add_theme_constant_override("h_separation", 10)
	shop_stats.add_theme_constant_override("v_separation", 1)
	sbox.add_child(shop_stats)


func open_shop(g: Game) -> void:
	var was_visible: bool = screens.shop.visible
	show_screen("shop")
	var p := g.player
	var gold := floori(p.gold)
	shop_title.text = "ONDA %d CONCLUÍDA" % g.wave
	var nxt := g.wave + 1
	shop_sub.text = "Próxima: onda %d. Um chefe espera por você." % nxt if Config.BOSS_WAVES.has(nxt) else "Próxima: onda %d de %d" % [nxt, Config.TOTAL_WAVES]
	shop_gold.text = str(gold)
	_clear(shop_cards)
	for i in g.shop_offers.size():
		var offer = g.shop_offers[i]
		if offer == null:
			var sold := PanelContainer.new()
			sold.custom_minimum_size = Vector2(196, 316)
			sold.add_theme_stylebox_override("panel", _box(Color.TRANSPARENT, Config.C_LINE, 2, 10))
			var l := _label("Comprado", 20, Config.C_MIST, FONT_BOLD, HORIZONTAL_ALIGNMENT_CENTER)
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sold.add_child(l)
			shop_cards.add_child(sold)
			continue
		var c := _card(offer, i + 1, offer.price, gold >= offer.price)
		c.pressed.connect(func(): g.buy(i))
		shop_cards.add_child(c)
	var cost := g.reroll_cost()
	reroll_btn.text = "Trocar ofertas  (%d)" % cost
	reroll_btn.modulate = Color(1, 1, 1, 1.0 if gold >= cost else 0.55)
	_fill_inventory(p, shop_weapons, shop_items)
	_fill_stats(shop_stats, p)
	if not was_visible:
		next_btn.grab_focus()


func _fill_inventory(p: Player, weapons_box: VBoxContainer, items_box: HFlowContainer) -> void:
	_clear(weapons_box)
	for s in p.weapons:
		var row := HBoxContainer.new()
		var iv := IconView.new()
		iv.weapon = s.w
		iv.custom_minimum_size = Vector2(24, 24)
		row.add_child(iv)
		var nm := _label(s.w.name, 17, Config.C_BONE, FONT_BOLD)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nm)
		row.add_child(_label("Nv %d" % s.level, 16, Config.C_MIST))
		weapons_box.add_child(row)
	weapons_box.add_child(_label("%d/%d espaços" % [p.weapons.size(), Config.MAX_WEAPONS], 14, Config.C_MIST))
	if items_box == null:
		return
	_clear(items_box)
	if p.items.is_empty():
		items_box.add_child(_label("Nenhum item ainda", 15, Config.C_MIST))
		return
	var counts := {}
	var order := []
	for it in p.items:
		if not counts.has(it.id):
			order.append(it)
		counts[it.id] = counts.get(it.id, 0) + 1
	for it in order:
		var opt := ItemDB.make_item_option(it, 1)
		var v := _icon(it.icon, opt.color, 30)
		v.tooltip_text = it.name
		v.mouse_filter = Control.MOUSE_FILTER_PASS
		v.badge = counts[it.id]
		items_box.add_child(v)


func _fill_stats(grid: GridContainer, p: Player) -> void:
	_clear(grid)
	for k in ItemDB.STAT_INFO:
		var info: Dictionary = ItemDB.STAT_INFO[k]
		var v: float = p.stats[k]
		var base: float = Player.BASE_STATS[k]
		var better: bool = v < base if info.get("invert", false) else v > base
		var col := Config.C_BONE
		if not is_equal_approx(v, base):
			col = Config.C_GOOD if better else Config.C_BAD
		var l := _label(info.get("short", info.label), 15, Config.C_MIST)
		l.custom_minimum_size.x = 100
		l.clip_text = true
		grid.add_child(l)
		grid.add_child(_label(ItemDB.format_stat_value(k, v), 15, col, FONT_BOLD, HORIZONTAL_ALIGNMENT_RIGHT))


# ---------- Pausa ----------

func _build_pause() -> void:
	var panel := _screen("pause")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_comic("PAUSADO", 64, Config.C_BONE, 12))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 30)
	box.add_child(cols)
	var wcol := VBoxContainer.new()
	wcol.custom_minimum_size = Vector2(280, 0)
	wcol.add_child(_h3("Armas"))
	pause_weapons = VBoxContainer.new()
	wcol.add_child(pause_weapons)
	cols.add_child(wcol)
	var scol := VBoxContainer.new()
	scol.add_child(_h3("Atributos"))
	pause_stats = GridContainer.new()
	pause_stats.columns = 4
	pause_stats.add_theme_constant_override("h_separation", 10)
	scol.add_child(pause_stats)
	cols.add_child(scol)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(actions)
	resume_btn = _button("Continuar", func(): game.toggle_pause(), true)
	actions.add_child(resume_btn)
	mute_btn = _button("", _on_mute)
	actions.add_child(mute_btn)
	quit_btn = _button("Desistir", _on_quit)
	quit_btn.add_theme_color_override("font_color", Config.C_BAD)
	quit_btn.add_theme_color_override("font_hover_color", Config.C_BAD)
	actions.add_child(quit_btn)


func _on_mute() -> void:
	Sfx.set_muted(not Sfx.muted)
	_update_mute_label()


func _on_quit() -> void:
	if not quit_armed:
		quit_armed = true
		quit_btn.text = "Confirmar desistência"
		return
	game.quit_to_menu()


func _update_mute_label() -> void:
	mute_btn.text = "Som: desligado" if Sfx.muted else "Som: ligado"


func show_pause(g: Game) -> void:
	quit_armed = false
	quit_btn.text = "Desistir"
	_update_mute_label()
	_fill_inventory(g.player, pause_weapons, null)
	_fill_stats(pause_stats, g.player)
	show_screen("pause")
	resume_btn.grab_focus()


# ---------- Fim de jogo ----------

func _build_end() -> void:
	var panel := _screen("end")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(520, 0)
	panel.add_child(box)
	end_title = _comic("", 80, Config.C_BAD, 14)
	box.add_child(end_title)
	end_sub = _wrap(_label("", 20, Config.C_MIST, null, HORIZONTAL_ALIGNMENT_CENTER), 520)
	box.add_child(end_sub)
	end_stats = GridContainer.new()
	end_stats.columns = 2
	end_stats.add_theme_constant_override("h_separation", 30)
	box.add_child(end_stats)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(actions)
	retry_btn = _button("Jogar de novo", _on_retry, true)
	retry_btn.custom_minimum_size = Vector2(260, 54)
	actions.add_child(retry_btn)
	actions.add_child(_button("Escolher herói", func(): game.quit_to_menu()))


func _on_retry() -> void:
	hide_screens()
	game.new_run(game.hero)


func show_end(g: Game, victory: bool) -> void:
	var p := g.player
	hud.visible = false
	hide_boss_bar()
	end_title.text = "VITÓRIA!" if victory else "VOCÊ CAIU"
	end_title.add_theme_color_override("font_color", Config.C_GOLD if victory else Config.C_BAD)
	end_sub.text = "%s derrotou A Calamidade e salvou o mundo." % p.hero.name if victory else "%s foi derrotado na onda %d." % [p.hero.name, g.wave]
	_clear(end_stats)
	var mins := int(g.run_time) / 60
	var secs := int(g.run_time) % 60
	for row in [["Onda", "%d / %d" % [g.wave, Config.TOTAL_WAVES]], ["Nível", str(p.level)], ["Inimigos derrotados", str(g.kills)],
			["Tempo", "%d:%02d" % [mins, secs]], ["Armas", ", ".join(PackedStringArray(p.weapons.map(func(s): return s.w.name)))]]:
		end_stats.add_child(_label(row[0], 19, Config.C_MIST))
		end_stats.add_child(_wrap(_label(row[1], 19, Config.C_BONE, FONT_BOLD), 300))
	retry_btn.text = "Jogar de novo"
	show_screen("end")
	retry_btn.grab_focus()


# ---------- Controles desenhados ----------

## Desenha um ícone, uma arma ou o retrato de um herói
class IconView extends Control:
	var icon := "star"
	var color := Color.WHITE
	var weapon: WeaponBase
	var hero: HeroBase
	var animate := false
	var badge := 0
	var t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if animate:
			t += delta
			queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var s := minf(size.x, size.y)
		if hero:
			hero.draw_body(self, c + Vector2(0, s * 0.08), s * 0.24, 1.0, t, {"moving": animate})
		elif weapon:
			weapon.draw_icon(self, c, s * 0.42)
		else:
			Icons.draw(self, icon, c, s * 0.42, color)
		if badge > 1:
			draw_string(GameUI.FONT_BOLD, Vector2(size.x - 12, size.y), "×%d" % badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Config.C_GOLD)


## Espaço de arma no HUD
class SlotView extends Control:
	var slot: WeaponSlot

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.1, 0.07, 0.13, 0.85 if slot else 0.35))
		draw_rect(r, Config.C_LINE, false, 2.0)
		if slot == null:
			return
		slot.w.draw_icon(self, size / 2.0, size.x * 0.33)
		var bc := Vector2(size.x - 4, size.y - 4)
		draw_circle(bc, 10.0, Config.C_GOLD, true, -1.0, true)
		draw_string(GameUI.FONT_BOLD, bc + Vector2(-4, 5), str(slot.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("2a1a00"))


## Botão redondo da habilidade, com a recarga desenhada como um "relógio"
class AbilityButton extends Control:
	var ui: GameUI

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			ui.game.touch_ability = event.pressed
			accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT and ui and ui.game:
			ui.game.touch_ability = false

	func _draw() -> void:
		var g := ui.game
		if g == null or g.player.hero == null:
			return
		var p := g.player
		var h := p.hero
		var c := size / 2.0
		var R := minf(size.x, size.y) / 2.0 - 3.0
		var frac := p.ability_timer / p.ability_cooldown()
		draw_circle(c, R, Color(0.1, 0.07, 0.13, 0.92), true, -1.0, true)
		Icons.draw(self, h.ability_icon, c, R * 0.5, h.ability_color)
		if frac > 0.0:
			var pts := PackedVector2Array([c])
			var n := 32
			for i in n + 1:
				pts.append(c + Vector2.from_angle(-PI / 2 + TAU * frac * i / n) * R)
			draw_colored_polygon(pts, Color(0.02, 0.01, 0.03, 0.72))
			var txt := str(ceili(p.ability_timer))
			var w := GameUI.FONT_COMIC.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
			draw_string_outline(GameUI.FONT_COMIC, c + Vector2(-w / 2.0, 14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, 6, Config.C_INK)
			draw_string(GameUI.FONT_COMIC, c + Vector2(-w / 2.0, 14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Config.C_BONE)
			draw_circle(c, R, Config.C_LINE, false, 3.0, true)
		else:
			draw_circle(c, R + 2.0 + sin(g.real_time * 5.0) * 1.5, Color(Config.C_GOLD, 0.35), false, 6.0, true)
			draw_circle(c, R, Config.C_GOLD, false, 3.0, true)
		var key := "ESPAÇO"
		var kw := GameUI.FONT_BOLD.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_rect(Rect2(c + Vector2(-kw / 2.0 - 6, -R - 12), Vector2(kw + 12, 20)), Config.C_PANEL_2)
		draw_string(GameUI.FONT_BOLD, c + Vector2(-kw / 2.0, -R + 3), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Config.C_MIST)


## Joystick virtual para telas de toque: nasce onde o dedo toca
class TouchPad extends Control:
	const MAX_R := 70.0
	var ui: GameUI
	var idx := -1
	var ability_idx := -1
	var base := Vector2.ZERO
	var cur := Vector2.ZERO

	func _input(event: InputEvent) -> void:
		var g := ui.game
		if g.state != Game.State.PLAYING:
			if idx != -1 or ability_idx != -1:
				idx = -1
				ability_idx = -1
				g.touch_move = Vector2.ZERO
				g.touch_ability = false
				queue_redraw()
			return
		if event is InputEventScreenTouch:
			if event.pressed:
				if ui.ability_btn.get_global_rect().has_point(event.position):
					ability_idx = event.index
					g.touch_ability = true
				elif ui.pause_btn.get_global_rect().has_point(event.position):
					return
				elif idx == -1:
					idx = event.index
					base = event.position
					cur = event.position
			else:
				if event.index == idx:
					idx = -1
					g.touch_move = Vector2.ZERO
				if event.index == ability_idx:
					ability_idx = -1
					g.touch_ability = false
			queue_redraw()
		elif event is InputEventScreenDrag and event.index == idx:
			cur = event.position
			var d := cur - base
			if d.length() > MAX_R:
				base = cur - d.normalized() * MAX_R
			var v := (cur - base) / MAX_R
			g.touch_move = v if v.length() > 0.08 else Vector2.ZERO
			queue_redraw()

	func _draw() -> void:
		if idx == -1:
			return
		draw_circle(base, MAX_R, Color(0.94, 0.9, 0.86, 0.4), false, 3.0, true)
		draw_circle(cur, 28.0, Color(0.94, 0.9, 0.86, 0.45), true, -1.0, true)
