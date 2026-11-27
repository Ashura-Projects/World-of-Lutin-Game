class_name AdvisorPanel
extends PanelContainer
## Campagne (1.4.1) : Maître Ombelin, le conseiller. Au début de chaque chapitre : la mini-cinématique dessinée,
## puis son récit (bulles, « Suite ▸ ») ; ensuite un petit cadre avec son portrait, la mission en cours,
## l'avancement et « Astuce » (son conseil). Chapitre fini : musique de victoire, récompense, chapitre suivant.
## Le cadre se replie (▾) pour libérer l'écran.

var game: Node
var _portrait: TextureRect
var _name: Label
var _text: Label
var _bar: ProgressBar
var _next: Button
var _tip: Button
var _fold: Button
var _lines: Array = []
var _line_i: int = 0
var _folded: bool = false
var _tip_on: bool = false


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.1, 0.08, 0.06, 0.94), UiStyle.GOLD, 2, 10))
	position = Vector2(12, 70)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	add_child(h)
	var cfg: Dictionary = DataRegistry.get_table("campaign").get("advisor", {})
	_portrait = TextureRect.new()
	_portrait.texture = load(str(cfg.get("portrait", "res://assets/ui/advisor.png")))
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.custom_minimum_size = Vector2(110, 110)
	h.add_child(_portrait)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	h.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_name = UiStyle.title_label("%s, %s" % [cfg.get("name", "Conseiller"), cfg.get("role", "")], 19)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_name)
	_fold = Button.new()
	_fold.text = "▾"
	_fold.custom_minimum_size = Vector2(46, 38)
	_fold.pressed.connect(_toggle_fold)
	head.add_child(_fold)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(430, 0)
	_text.add_theme_font_size_override("font_size", 17)
	v.add_child(_text)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(430, 14)
	_bar.show_percentage = false
	v.add_child(_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	_next = Button.new()
	_next.text = "Suite ▸"
	_next.custom_minimum_size = Vector2(130, 42)
	_next.pressed.connect(_on_next)
	row.add_child(_next)
	_tip = Button.new()
	_tip.text = "Astuce"
	_tip.custom_minimum_size = Vector2(130, 42)
	_tip.pressed.connect(func() -> void: _tip_on = not _tip_on)
	row.add_child(_tip)
	var ms: TutorialMissions = game.sim.missions
	ms.chapter_done.connect(_on_chapter_done)
	ms.all_done.connect(_on_all_done)
	ms.mission_done.connect(func(t: String) -> void: EventBus.alert.emit("objectif", "Mission réussie : %s" % t))


## Début (ou reprise) d'un chapitre : sa cinématique puis le récit du conseiller.
func start_chapter(with_cinematic: bool = true) -> void:
	var ch: Dictionary = game.sim.missions.chapter_def()
	if ch.is_empty():
		return
	Audio.play_mood(str(ch.get("mood", "peace")))
	if with_cinematic:
		var cine := CinematicPlayer.new()
		game.hud.root.add_child(cine)
		GameClock.running = false
		if cine.play(str(ch.get("cinematic", ""))):
			cine.finished.connect(
				func() -> void:
					GameClock.running = true
					Audio.play_mood(str(ch.get("mood", "peace")))
					_tell(ch)
			)
			return
		cine.queue_free()
		GameClock.running = true
	_tell(ch)


func _tell(ch: Dictionary) -> void:
	_lines = Array(ch.get("story", [])).duplicate()
	_line_i = 0
	_folded = false
	visible = true


func _on_next() -> void:
	_line_i += 1


func _toggle_fold() -> void:
	_folded = not _folded


func _process(_d: float) -> void:
	if Engine.get_process_frames() % 10 != 0:
		return
	var ms: TutorialMissions = game.sim.missions
	var ch := ms.chapter_def()
	_fold.text = "▸" if _folded else "▾"
	_portrait.visible = not _folded
	_text.visible = not _folded
	_tip.visible = not _folded
	if _line_i < _lines.size():  # récit du chapitre
		_text.text = "« %s »" % _lines[_line_i]
		_name.text = "Chapitre %d — %s" % [int(ch.get("id", 0)), ch.get("title", "")]
		_bar.visible = false
		_next.visible = not _folded
		return
	_next.visible = false
	var m := ms.current()
	if m.is_empty():
		_text.text = "Bravo !"
		return
	var p := ms.progress()
	_name.text = "Chapitre %d · %s" % [int(ch.get("id", 0)), m["title"]]
	_text.text = "%s  (%d / %d)%s" % [m["goal"], p[0], p[1], ("\n💡 " + str(m.get("hint", ""))) if _tip_on else ""]
	_bar.visible = true
	_bar.max_value = p[1]
	_bar.value = p[0]


## Chapitre fini : musique de victoire un moment, puis le chapitre suivant.
func _on_chapter_done(_c: int) -> void:
	Audio.play_mood("victory")
	_tip_on = false
	if not game.sim.missions.finished:
		get_tree().create_timer(4.0).timeout.connect(func() -> void: start_chapter(true))


func _on_all_done() -> void:
	var cfg := DataRegistry.get_table("campaign")
	_lines = [str(cfg.get("done_title", "")), str(cfg.get("done_text", ""))]
	_line_i = 0
	visible = true
	Audio.play_mood("victory")
