extends Node2D
## Desenha uma camada do mundo a cada quadro (chão, coletáveis, inimigos, projéteis
## ou efeitos). Desenhar tudo de uma vez numa camada é bem mais leve do que um nó por inimigo.

enum Kind { GROUND, PICKUPS, ENEMIES, PROJECTILES, TOP }

@export var kind: Kind = Kind.GROUND


func _draw() -> void:
	var g := Game.I
	if g == null:
		return
	var t := g.time
	match kind:
		Kind.GROUND:
			for s in g.spawn_queue:
				var a := 0.4 + 0.4 * sin(s.t * 20.0)
				var col := Color(Config.C_GOLD, a) if s.elite else Color(1.0, 0.28, 0.24, a)
				var p: Vector2 = s.pos
				draw_line(p + Vector2(-9, -9), p + Vector2(9, 9), col, 3.0, true)
				draw_line(p + Vector2(9, -9), p + Vector2(-9, 9), col, 3.0, true)
			for f in g.fx_under:
				f.draw(self)
			if g.state != Game.State.MENU:
				for slot in g.player.weapons:
					slot.w.draw_world(self, g, slot)
		Kind.PICKUPS:
			for pk in g.pickups:
				Art.pickup(self, pk, t)
		Kind.ENEMIES:
			var px := g.player.position.x
			for e in g.enemies:
				if not e.boss and e.def.behavior != "phase":
					Art.shadow(self, e.pos, e.r)
			for e in g.enemies:
				e.draw(self, t, px)
		Kind.PROJECTILES:
			for pr in g.projectiles:
				Art.projectile(self, pr)
			for b in g.enemy_bullets:
				Art.enemy_bullet(self, b)
		Kind.TOP:
			for f in g.fx_top:
				f.draw(self)
			for pt in g.particles:
				var s: float = pt.size
				draw_rect(Rect2(pt.pos - Vector2(s, s) / 2.0, Vector2(s, s)), Color(pt.color, clampf(pt.life / pt.max_life, 0.0, 1.0)))
			for tx in g.texts:
				tx.draw(self)
