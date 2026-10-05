class_name Config
## Constantes globais do jogo. Mude aqui para ajustar a partida.

const ARENA := Vector2(1800, 1300)
const TOTAL_WAVES := 20
const MAX_WEAPONS := 6
const MAX_ENEMIES := 220
const BASE_MOVE_SPEED := 210.0
## Ondas com chefe: número da onda -> id do chefe em EnemyDB.BOSSES
const BOSS_WAVES := {10: "herald", 20: "calamity"}

const SAVE_PATH := "user://save.cfg"

# Paleta da interface
const C_VOID := Color("0e0a12")
const C_PANEL := Color("1a1320")
const C_PANEL_2 := Color("251b2c")
const C_LINE := Color("3b2c44")
const C_BONE := Color("efe6dc")
const C_MIST := Color("a597ad")
const C_EMBER := Color("ff6a3d")
const C_GOLD := Color("f2c14e")
const C_HP := Color("e5484d")
const C_XP := Color("5fd3a8")
const C_GOOD := Color("8be39a")
const C_BAD := Color("ff8a80")
const C_INK := Color("120a10")
