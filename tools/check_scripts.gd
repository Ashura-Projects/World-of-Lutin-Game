extends SceneTree
## Vérifie que tous les scripts de src/ et tools/ se compilent (les erreurs s'affichent en « SCRIPT ERROR »).
## Usage : godot --headless -s tools/check_scripts.gd


func _initialize() -> void:
	var n := 0
	for dir: String in ["res://src", "res://tools"]:
		n += _scan(dir)
	print("SCRIPTS OK : %d chargés" % n)
	quit()


func _scan(path: String) -> int:
	var n := 0
	var d := DirAccess.open(path)
	if d == null:
		return 0
	for f in d.get_files():
		if f.ends_with(".gd") and f != "check_scripts.gd":
			var s: Script = load(path + "/" + f)
			if s == null or not s.can_instantiate():
				printerr("ÉCHEC : ", path + "/" + f)
			n += 1
	for sub in d.get_directories():
		n += _scan(path + "/" + sub)
	return n
