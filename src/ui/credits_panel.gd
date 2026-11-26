class_name CreditsPanel
extends PanelContainer
## Crédits : projet d'Ashura ; outils et ressources libres utilisés.


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(700, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	v.add_child(UiStyle.title_label("World of Lutin", 36))
	var l := Label.new()
	l.text = "\n".join([
		"Un projet d'Ashura.", "",
		"Modèles, textures, musiques et sons faits pour le jeu (Blender, scripts).",
		"Moteur : Godot Engine (licence MIT).",
		"Police des titres : Cinzel (SIL Open Font License).",
		"Tests : GUT (MIT).", "", "Merci d'avoir joué !",
	])
	v.add_child(l)
	var ok := Button.new()
	ok.text = "Fermer"
	ok.custom_minimum_size = Vector2(300, 54)
	ok.pressed.connect(queue_free)
	v.add_child(ok)
