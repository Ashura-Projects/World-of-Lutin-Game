extends Node
## Mesure : génération de la carte et maillage de tous les chunks (temps CPU, faces).
## Usage : godot --headless res://tools/bench/bench_world.tscn -- <taille medium|large> <graine>

var _done := false


func _process(_delta: float) -> void:
	if not _done:
		_done = true
		_run()
		get_tree().quit()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var size_id := args[0] if args.size() > 0 else "small"
	var seed_value := int(args[1]) if args.size() > 1 else 1234
	var gs := GameSetup
	gs.map_size = size_id
	var t0 := Time.get_ticks_msec()
	var w := VoxelWorld.new(gs.map_dims())
	var g := WorldGenerator.new(w, seed_value)
	g.generate()
	var t1 := Time.get_ticks_msec()
	var faces := 0
	var worst := 0
	var n := 0
	for k: Vector3i in w.chunk_keys().slice(0, 1200):
		var a := Time.get_ticks_usec()
		faces += int(ChunkMesher.build(w, k)["faces"])
		worst = maxi(worst, Time.get_ticks_usec() - a)
		n += 1
	var t2 := Time.get_ticks_msec()
	print(
		(
			"BENCH taille=%s generation=%dms chunks=%d maillage_total=%dms pire_chunk=%.1fms faces=%d triangles=%d arbres=%d"
			% [size_id, t1 - t0, n, t2 - t1, worst / 1000.0, faces, faces * 2, g.trees.size()]
		)
	)
