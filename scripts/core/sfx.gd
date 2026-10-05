extends Node
## Efeitos sonoros sintetizados na inicialização (nenhum arquivo de áudio).
## Uso: Sfx.play("hit")

const RATE := 22050

var streams := {}
var players: Array[AudioStreamPlayer] = []
var last_play := {}
var muted := false

# Intervalo mínimo entre repetições (ms), evita barulho excessivo
const GAPS := {"hit": 50, "kill": 40, "pickup": 30, "shoot": 70, "swing": 90, "zap": 80, "explode": 90, "laser": 90}


func _ready() -> void:
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	var cfg := ConfigFile.new()
	if cfg.load(Config.SAVE_PATH) == OK:
		muted = cfg.get_value("settings", "muted", false)
	_build_all()


func set_muted(m: bool) -> void:
	muted = m
	var cfg := ConfigFile.new()
	cfg.load(Config.SAVE_PATH)
	cfg.set_value("settings", "muted", m)
	cfg.save(Config.SAVE_PATH)


func play(sound: String, pitch_jitter: float = 0.06) -> void:
	if muted or not streams.has(sound):
		return
	var now := Time.get_ticks_msec()
	var gap: int = GAPS.get(sound, 0)
	if gap > 0 and now - int(last_play.get(sound, -100000)) < gap:
		return
	last_play[sound] = now
	var player: AudioStreamPlayer = null
	for p in players:
		if not p.playing:
			player = p
			break
	if player == null:
		player = players[0]
		players.push_back(players.pop_front())
	player.stream = streams[sound]
	player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	player.play()


# ---------- Síntese ----------

var _buf := PackedFloat32Array()


func _begin(dur: float) -> void:
	_buf = PackedFloat32Array()
	_buf.resize(int(dur * RATE))


func _end(sound: String) -> void:
	var data := PackedByteArray()
	data.resize(_buf.size() * 2)
	for i in _buf.size():
		data.encode_s16(i * 2, int(clampf(_buf[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	streams[sound] = s


func _tone(freq: float, dur: float, wave: String, vol: float, slide: float = 1.0, delay: float = 0.0) -> void:
	var start := int(delay * RATE)
	var n := int(dur * RATE)
	var phase := 0.0
	for i in n:
		var idx := start + i
		if idx >= _buf.size():
			break
		var k := float(i) / n
		phase += freq * pow(slide, k) / RATE
		var x := fmod(phase, 1.0)
		var s := 0.0
		match wave:
			"sine": s = sin(TAU * x)
			"square": s = 1.0 if x < 0.5 else -1.0
			"triangle": s = 4.0 * absf(x - 0.5) - 1.0
			_: s = 2.0 * x - 1.0
		_buf[idx] += s * vol * pow(0.001 / vol, k)


func _noise(dur: float, vol: float, cutoff: float, delay: float = 0.0) -> void:
	var start := int(delay * RATE)
	var n := int(dur * RATE)
	var a := 1.0 - exp(-TAU * cutoff / RATE)
	var y := 0.0
	for i in n:
		var idx := start + i
		if idx >= _buf.size():
			break
		y += a * (randf() * 2.0 - 1.0 - y)
		_buf[idx] += y * vol * 2.0 * pow(0.001 / vol, float(i) / n)


func _build_all() -> void:
	_begin(0.06); _tone(200, 0.05, "square", 0.12, 0.5); _end("hit")
	_begin(0.08); _noise(0.07, 0.25, 900); _end("kill")
	_begin(0.06); _tone(1000, 0.05, "sine", 0.18, 1.4); _end("pickup")
	_begin(0.07); _tone(560, 0.06, "triangle", 0.15, 0.6); _end("shoot")
	_begin(0.1); _noise(0.09, 0.2, 2600); _end("swing")
	_begin(0.09); _tone(1400, 0.08, "saw", 0.12, 0.3); _end("zap")
	_begin(0.12); _tone(1800, 0.11, "saw", 0.1, 0.4); _end("laser")
	_begin(0.32); _noise(0.3, 0.5, 500); _end("explode")
	_begin(0.24); _tone(150, 0.22, "saw", 0.4, 0.4); _end("hurt")
	_begin(0.38); _tone(260, 0.35, "saw", 0.25, 3.0); _noise(0.3, 0.2, 2000); _end("ability")
	_begin(0.45)
	for i in 4:
		_tone([523.0, 659.0, 784.0, 1046.0][i], 0.14, "triangle", 0.3, 1.0, i * 0.07)
	_end("levelup")
	_begin(0.18); _tone(660, 0.08, "triangle", 0.3); _tone(990, 0.1, "triangle", 0.3, 1.0, 0.06); _end("buy")
	_begin(0.15); _tone(120, 0.14, "square", 0.2); _end("deny")
	_begin(0.52); _tone(330, 0.5, "triangle", 0.3, 2.0); _end("wave")
	_begin(1.25); _tone(70, 1.2, "saw", 0.4, 0.6); _noise(1.0, 0.25, 300); _end("boss")
	_begin(0.4)
	for i in 5:
		_tone([392.0, 523.0, 659.0, 784.0, 1046.0][i], 0.12, "square", 0.14, 1.0, i * 0.05)
	_end("chest")
	_begin(1.0); _tone(220, 1.0, "saw", 0.35, 0.2); _end("death")
	_begin(0.9)
	for i in 6:
		_tone([523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0][i], 0.22, "triangle", 0.3, 1.0, i * 0.12)
	_end("victory")
	_begin(0.4); _noise(0.35, 0.25, 4000); _tone(1200, 0.3, "sine", 0.15, 1.5); _end("freeze")
	_begin(0.15); _noise(0.12, 0.25, 1500); _end("web")
