class_name SoundDirector
extends Node3D
## Relie le jeu au son : ambiances selon ce que regarde la caméra (eau, arbres, feux, altitude, nuit),
## bruits de travail des lutins proches, coups de fusil, hurlements, cloche, naissances, objectifs.

var game: Node
var _t: float = 0.0
var _work_timers: Dictionary = {}
var _cfg: Dictionary


func setup(g: Node) -> void:
	game = g
	_cfg = DataRegistry.get_table("audio")
	Audio.world_root = self
	EventBus.sfx.connect(func(n: String, p: Vector3) -> void: Audio.play_at(n, p))
	EventBus.alert.connect(_on_alert)
	Audio.start_music()


func _on_alert(kind: String, _text: String) -> void:
	match kind:
		"cloche":
			Audio.play_ui("cloche")
		"naissance":
			Audio.play_ui("naissance")
		"objectif", "rang", "recherche", "formation":
			Audio.play_ui("fanfare")


func _process(delta: float) -> void:
	if game.sim == null:
		return
	var cam: CameraController = game.camera
	Audio.zoom_distance = cam.distance
	Audio.listener_pos = cam.target
	Audio.set_night(GameClock.is_night())
	_t += delta
	if _t >= 0.5:
		_t = 0.0
		_update_ambience(cam.target)
	_work_sounds(delta, cam.target)


func _update_ambience(center: Vector3) -> void:
	var w: VoxelWorld = game.world
	var r := int(_cfg.get("listen_radius", 14))
	var c := Vector3i(center)
	var water := 0
	var samples := 0
	var top_sum := 0.0
	for x in range(c.x - r, c.x + r + 1, 3):
		for z in range(c.z - r, c.z + r + 1, 3):
			var y := w.surface_y(x, z)
			if y < 0:
				continue
			samples += 1
			top_sum += y
			if (
				w.types.liquid[w.get_block(Vector3i(x, y - 1, z))] == 1
				or w.types.liquid[w.get_block(Vector3i(x, y, z))] == 1
			):
				water += 1
	var trees := 0
	for p: Vector3i in game.flora.trees:
		if absi(p.x - c.x) <= r and absi(p.z - c.z) <= r:
			trees += 1
	var fires := 0.0
	for s: Dictionary in game.structures.items.values():
		if s["built"] and Structures.def(s["kind"]).has("warmth") and Vector3(s["cell"]).distance_to(center) < r:
			fires = 1.0
	var night := GameClock.is_night()
	var height := top_sum / maxf(1.0, samples)
	var sea := float(DataRegistry.get_table("world").get("sea_level", 24))
	(
		Audio
		. set_ambience(
			{
				"foret": 0.0 if night else clampf(trees / 12.0, 0.0, 1.0),
				"nuit": 0.8 if night else 0.0,
				"eau": clampf(water * 4.0 / maxf(1.0, samples), 0.0, 1.0),
				"vent": clampf((height - sea - 8.0) / 20.0, 0.1, 1.0),
				"feu": fires,
			}
		)
	)
	if night and Rng.randf() < float(_cfg.get("howl_chance_per_s_night", 0.01)) * 0.5:
		for a: Dictionary in game.fauna.animals:
			if a["kind"] == "wolf" and Vector3(a["pos"]).distance_to(center) < 60:
				Audio.play_at("loup", a["pos"])
				break


func _work_sounds(delta: float, center: Vector3) -> void:
	var sounds: Dictionary = _cfg.get("work_sounds", {})
	var every := float(_cfg.get("work_sound_every_s", 1.1))
	for l: Lutin in game.colony.lutins:
		if l.state != Lutin.State.WORK or l.pos.distance_to(center) > 30.0:
			continue
		var t: Dictionary = game.board.tasks.get(l.task_id, {})
		var snd: String = sounds.get(t.get("kind", ""), "")
		if snd == "":
			continue
		_work_timers[l.id] = float(_work_timers.get(l.id, randf() * every)) - delta * GameClock.speed
		if _work_timers[l.id] <= 0.0:
			_work_timers[l.id] = every
			Audio.play_at(snd, l.pos + Vector3(0, 0.6, 0))
