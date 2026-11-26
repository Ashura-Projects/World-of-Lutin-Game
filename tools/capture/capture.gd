extends SceneTree
## Capture d'écran automatique du jeu (vérification visuelle dans le cloud, sous Xvfb).
## Usage : xvfb-run godot --rendering-driver opengl3 -s tools/capture/capture.gd -- <sortie.png> [scene] [attente_s] [graine] [taille]

var _out := "build/captures/capture.png"
var _wait := 6.0
var _t := 0.0
var _scene := "res://src/game/game.tscn"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1 and args[1] != "":
		_scene = args[1]
	if args.size() > 2:
		_wait = float(args[2])
	var gs := root.get_node_or_null("GameSetup")
	if gs:
		gs.reset_defaults()
		if args.size() > 3:
			gs.seed_value = int(args[3])
		if args.size() > 4:
			gs.map_size = args[4]
	change_scene_to_file(_scene)


func _process(delta: float) -> bool:
	_t += delta
	var game := current_scene
	var ready: bool = (
		game != null and (not ("world_view" in game) or (game.world_view != null and game.world_view.is_idle()))
	)
	if _t > _wait and ready:
		var img := root.get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(_out.get_base_dir())
		img.save_png(_out)
		print("CAPTURE ", _out, " fps=", Engine.get_frames_per_second())
		quit()
	if _t > _wait + 120.0:
		print("CAPTURE délai dépassé")
		quit(1)
	return false
