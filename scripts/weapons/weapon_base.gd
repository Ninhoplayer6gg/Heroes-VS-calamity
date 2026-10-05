class_name WeaponBase
extends RefCounted
## Base de todas as armas. Cada arma ataca sozinha quando a recarga termina.
##   stats(nivel)  -> números da arma naquele nível (1 a max_level)
##   fire(...)     -> ataca; retorna true se atacou (false = sem alvo, tenta logo de novo)
##   update(...)   -> lógica contínua (opcional, ex.: lâminas orbitais)
##   draw_under / draw_over -> desenho em volta do jogador (coordenadas locais do jogador)
##   draw_world    -> desenho no mundo (ex.: rastro elétrico)

const LABELS := {
	"damage": "Dano",
	"cooldown": "Recarga",
	"count": "Quantidade",
	"pierce": "Perfuração",
	"bounces": "Ricochetes",
	"chains": "Saltos",
	"radius": "Raio",
	"range": "Alcance",
	"duration": "Duração",
}

var id := ""
var name := ""
var desc := ""
var icon := "star"
var color := Color.WHITE
var max_level := 5
## Se preenchido, só este herói pode receber a arma (arma exclusiva)
var hero_only := ""
## false para armas contínuas, que não usam recarga
var uses_cooldown := true


func stats(_lv: int) -> Dictionary:
	return {"cooldown": 1.0}


func fire(_game: Game, _p: Player, _slot: WeaponSlot, _s: Dictionary) -> bool:
	return false


func update(_game: Game, _p: Player, _slot: WeaponSlot, _s: Dictionary, _dt: float) -> void:
	pass


func draw_under(_ci: CanvasItem, _p: Player, _slot: WeaponSlot, _s: Dictionary) -> void:
	pass


func draw_over(_ci: CanvasItem, _p: Player, _slot: WeaponSlot, _s: Dictionary) -> void:
	pass


func draw_world(_ci: CanvasItem, _game: Game, _slot: WeaponSlot) -> void:
	pass


func draw_icon(ci: CanvasItem, c: Vector2, s: float) -> void:
	Icons.draw(ci, icon, c, s, color)


## Quantidade total de disparos (base + projéteis extras do jogador)
func total_count(p: Player, s: Dictionary) -> int:
	return int(s.get("count", 1)) + int(p.stats.projectiles)


## Ângulos em leque centrados em base_angle
func fan(base_angle: float, n: int, spread: float) -> Array:
	var out := []
	for i in n:
		out.append(base_angle + (i - (n - 1) / 2.0) * spread)
	return out


## Lista legível das mudanças de um nível para o próximo (ex.: "Dano 21 → 28")
func level_changes(from_lv: int) -> Array:
	var a := stats(from_lv)
	var b := stats(from_lv + 1)
	var out := []
	for k in LABELS:
		if not a.has(k) or is_equal_approx(float(a[k]), float(b[k])):
			continue
		out.append({"text": "%s %s → %s" % [LABELS[k], _fmt(k, a[k]), _fmt(k, b[k])], "good": true})
	return out


func _fmt(k: String, v) -> String:
	match k:
		"cooldown":
			return U.fmt_num(v, 2) + "s"
		"duration":
			return U.fmt_num(v, 1) + "s"
		_:
			return str(roundi(v))
