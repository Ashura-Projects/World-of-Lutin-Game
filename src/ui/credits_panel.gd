class_name CreditsPanel
extends PanelContainer
## Crédits : projet d'Ashura ; outils et ressources libres utilisés.


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(700, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	v.add_child(UiStyle.header("World of Lutins", 36, queue_free))
	var l := Label.new()
	l.text = (
		"\n"
		. join(
			[
				"Un projet d'Ashura.",
				"",
				"Modèles, textures, ambiances et bruitages faits pour le jeu (Blender, scripts).",
				"",
				"Musiques : Kevin MacLeod (incompetech.com), licence Creative Commons BY 4.0 :",
				"Thatched Villagers, Village Consort, Minstrel Guild, Teller of the Tales,",
				"Folk Round, Achaidh Cheide, Pippin the Hunchback.",
				"",
				"Moteur : Godot Engine (licence MIT).",
				"Police des titres : Cinzel (SIL Open Font License).",
				"Tests : GUT (MIT).",
				"",
				"Merci d'avoir joué !",
			]
		)
	)
	v.add_child(l)
