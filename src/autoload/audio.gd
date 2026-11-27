extends Node
## Son du jeu : playlist de musiques (réglée dans Paramètres), ambiances qui suivent la caméra et le zoom,
## bruitages positionnés. Ambiances et bruitages : tools/audio/generate_audio.py ; musiques : voir data/audio.json.

const DIR := "res://assets/audio/"
const AMBIENCES := ["foret", "eau", "nuit", "vent", "feu"]

var listener_pos := Vector3.ZERO
var zoom_distance: float = 30.0
var _cfg: Dictionary
var _music: AudioStreamPlayer
var _amb: Dictionary = {}
var _amb_target: Dictionary = {}
var _pool: Array[AudioStreamPlayer3D] = []
var _ui: AudioStreamPlayer
var _streams: Dictionary = {}
var _track: int = -1
var current_track: String = ""
var world_root: Node3D = null  # parent des sons 3D (scène de jeu)


func _ready() -> void:
	_cfg = DataRegistry.get_table("audio")
	for bus in ["Musique", "Ambiance", "Effets"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	_music = AudioStreamPlayer.new()
	_music.bus = "Musique"
	_music.volume_db = float(_cfg.get("music_db", -8))
	_music.finished.connect(_next_track)
	add_child(_music)
	for a: String in AMBIENCES:
		var p := AudioStreamPlayer.new()
		p.bus = "Ambiance"
		p.stream = _load("ambience/" + a, true)
		p.volume_db = -80.0
		add_child(p)
		_amb[a] = p
		_amb_target[a] = 0.0
	_ui = AudioStreamPlayer.new()
	_ui.bus = "Effets"
	add_child(_ui)
	apply_volumes()


func _load(name: String, loop: bool = false) -> AudioStream:
	if _streams.has(name):
		return _streams[name]
	var path := DIR + name + ".ogg"
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path)
	if s is AudioStreamOggVorbis:
		s.loop = loop
	_streams[name] = s
	return s


## Volumes du joueur (Paramètres : musique, effets ; 0..1).
func apply_volumes() -> void:
	var m := float(Settings.get_value("music") if Settings.get_value("music") != null else 0.7)
	var e := float(Settings.get_value("effects") if Settings.get_value("effects") != null else 0.8)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Musique"), linear_to_db(maxf(m, 0.001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambiance"), linear_to_db(maxf(e, 0.001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effets"), linear_to_db(maxf(e, 0.001)))


func start_music() -> void:
	if not _music.playing:
		_next_track()


func stop_all() -> void:
	_music.stop()
	for p: AudioStreamPlayer in _amb.values():
		p.stop()
	for k: String in _amb_target:
		_amb_target[k] = 0.0


## Morceaux de la playlist : [{id, title, author, license}].
func tracks() -> Array:
	return _cfg.get("music", [])


## Morceaux cochés par le joueur (aucun coché = tous).
func playlist() -> Array:
	var chosen: Array = Settings.get_value("playlist") if Settings.get_value("playlist") != null else []
	var out := []
	for t: Dictionary in tracks():
		if chosen.is_empty() or chosen.has(t["id"]):
			out.append(t["id"])
	return out


func _next_track() -> void:
	var list := playlist()
	if list.is_empty():
		return
	var mode := str(Settings.get_value("music_mode"))
	var id: String
	if mode == "one" and str(Settings.get_value("music_track")) != "":
		id = str(Settings.get_value("music_track"))
	elif mode == "shuffle":
		id = str(list[randi() % list.size()])
		if list.size() > 1 and id == current_track:
			id = str(list[(list.find(id) + 1) % list.size()])
	else:
		_track = (list.find(current_track) + 1) % list.size()
		id = str(list[_track])
	play_track(id)


## Joue un morceau tout de suite (bouton ▶ des Paramètres).
func play_track(id: String) -> void:
	current_track = id
	_music.stream = _load("music/" + id)
	_music.play()


func set_night(_n: bool) -> void:
	pass  # la playlist ne change plus entre le jour et la nuit


## Ambiances voulues (0..1), lissées ensuite. Le zoom rapproché les rend plus fortes.
func set_ambience(levels: Dictionary) -> void:
	var near := float(_cfg.get("zoom_near", 8))
	var far := float(_cfg.get("zoom_far", 90))
	var z := clampf(1.0 - (zoom_distance - near) / (far - near), 0.15, 1.0)
	for k: String in _amb_target:
		_amb_target[k] = clampf(float(levels.get(k, 0.0)), 0.0, 1.0) * z


func _process(delta: float) -> void:
	var base := float(_cfg.get("ambience_db", -6))
	for k: String in _amb:
		var p: AudioStreamPlayer = _amb[k]
		var cur := db_to_linear(p.volume_db) if p.playing else 0.0
		var target: float = _amb_target[k]
		cur = move_toward(cur, target, delta * 0.4)
		if cur > 0.01 and not p.playing:
			p.play()
		elif cur <= 0.01 and p.playing and target <= 0.0:
			p.stop()
		p.volume_db = linear_to_db(maxf(cur, 0.0001)) + base


## Bruitage dans le monde (atténué avec la distance à la caméra).
func play_at(name: String, pos: Vector3) -> void:
	if world_root == null or not is_instance_valid(world_root):
		return
	var s := _load("sfx/" + name)
	if s == null:
		return
	var p: AudioStreamPlayer3D = null
	for q in _pool:
		if is_instance_valid(q) and not q.playing:
			p = q
			break
	if p == null:
		if _pool.size() >= 12:
			return
		p = AudioStreamPlayer3D.new()
		p.bus = "Effets"
		p.unit_size = 6.0
		p.max_distance = 70.0
		world_root.add_child(p)
		_pool.append(p)
	p.stream = s
	p.volume_db = float(_cfg.get("sfx_db", -4))
	p.pitch_scale = randf_range(0.92, 1.08)
	p.global_position = pos
	p.play()


func play_ui(name: String) -> void:
	var s := _load("sfx/" + name)
	if s:
		_ui.stream = s
		_ui.play()
