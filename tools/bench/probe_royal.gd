extends Node
## Sonde : nouvelle partie en Aventure Royale (camps d'orcs, villages voisins) sans affichage.


func _ready() -> void:
	GameSetup.reset_defaults()
	GameSetup.set_mode("royal")
	GameSetup.map_size = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "small"
	var w := VoxelWorld.new(GameSetup.map_dims())
	var g := WorldGenerator.new(w, 42)
	g.generate()
	var sim := GameSim.new(w)
	print("rules orcs=", sim.rules.orcs, " ai=", sim.rules.ai_factions)
	var start := Vector3i(w.size.x / 2, w.surface_y(w.size.x / 2, w.size.z / 2), w.size.z / 2)
	var t0 := Time.get_ticks_msec()
	sim.new_game(g, start, 6)
	print(
		"camps=",
		sim.orcs.camps.size(),
		" villages=",
		sim.rivals.states.size(),
		" arbres=",
		sim.flora.trees.size(),
		" ms=",
		Time.get_ticks_msec() - t0
	)
	get_tree().quit()
