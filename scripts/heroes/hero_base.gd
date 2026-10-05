class_name HeroBase
extends RefCounted
## Base dos heróis. Cada herói define atributos (mods), arma inicial,
## habilidade especial (cast) e o próprio visual (draw_body).

var id := ""
var name := ""
var title := ""
var desc := ""
var color := Color.WHITE
var dark := Color.BLACK
var start_weapon := ""
## Somados aos atributos base (veja Player.BASE_STATS)
var mods := {}
var ability_name := ""
var ability_desc := ""
var ability_icon := "star"
var ability_color := Color.WHITE
var ability_cooldown := 12.0


## Habilidade especial (Espaço)
func cast(_game: Game, _p: Player) -> void:
	pass


## Desenha o herói centrado em c. opts: moving (bool), flash (bool)
func draw_body(ci: CanvasItem, c: Vector2, r: float, facing: float, t: float, opts: Dictionary = {}) -> void:
	var cy := c - Vector2(0, bob(t, opts))
	Art.shadow(ci, c, r)
	Art.body(ci, cy, r, body_color(opts))
	Art.eyes(ci, cy, r, facing)


## Direção da habilidade: mira o inimigo mais próximo (o chefe tem prioridade);
## sem alvo, usa a direção do movimento
func aim_dir(game: Game, p: Player, reach: float) -> Vector2:
	var t := game.nearest_enemy(p.position, reach)
	return (t.pos - p.position).normalized() if t else p.dir


## Pulinho ao andar
func bob(t: float, opts: Dictionary) -> float:
	return absf(sin(t * 11.0)) * 3.0 if opts.get("moving", false) else sin(t * 2.2)


func body_color(opts: Dictionary, base: Color = color) -> Color:
	return Color.WHITE if opts.get("flash", false) else base
