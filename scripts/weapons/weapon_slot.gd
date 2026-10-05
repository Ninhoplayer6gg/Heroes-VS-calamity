class_name WeaponSlot
extends RefCounted
## Uma arma equipada pelo jogador: qual arma, nível, recarga e dados próprios.

var w: WeaponBase
var level := 1
var timer := 0.3
var data := {}


func _init(weapon: WeaponBase) -> void:
	w = weapon
	timer = randf_range(0.2, 0.5)


func stats() -> Dictionary:
	return w.stats(level)
