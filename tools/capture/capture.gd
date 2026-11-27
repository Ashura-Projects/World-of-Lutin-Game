extends SceneTree
## Capture d'écran automatique du jeu (vérification visuelle dans le cloud, sous Xvfb).
## Usage : xvfb-run godot --rendering-driver opengl3 -s tools/capture/capture.gd -- <sortie.png> [scene] [attente_s] [graine] [taille]

var _out := "build/captures/capture.png"
var _wait := 6.0
var _t := 0.0
var _scene := "res://src/game/game.tscn"
var _action := ""
var _action_done_at := -1.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1 and args[1] != "":
		_scene = args[1]
	if args.size() > 2:
		_wait = float(args[2])
	_setup.call_deferred(args)


## Réglages de la partie une fois les autoloads (données) prêts, puis lancement de la scène.
func _setup(args: Array) -> void:
	var gs := root.get_node_or_null("GameSetup")
	var st := root.get_node_or_null("Settings")
	if st:
		st.values["tutorial"] = false  # pas de conseils sur les captures
	if gs:
		gs.reset_defaults()
		if args.size() > 3:
			gs.seed_value = int(args[3])
		if args.size() > 4:
			gs.map_size = args[4]
	if args.size() > 5:
		_action = args[5]
	if args.size() > 6 and gs:
		gs.set_mode(args[6])  # sandbox / royal
	change_scene_to_file(_scene)


func _process(delta: float) -> bool:
	_t += delta
	var game := current_scene
	var ready: bool = (
		game != null and (not ("world_view" in game) or (game.world_view != null and game.world_view.is_idle()))
	)
	if _action != "" and ready and _action_done_at < 0.0:
		load("res://tools/capture/demos.gd").run(game, _action)
		_action_done_at = _t
		return false
	if (
		_action != ""
		and (
			_t
			< (
				_action_done_at
				+ (
					25.0
					if _action in ["travail", "village", "ferme", "v132_unite", "v14_units"]
					else (6.0 if _action == "loups" else 3.0)
				)
			)
		)
	):
		return false
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
