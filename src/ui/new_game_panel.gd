class_name NewGamePanel
extends PanelContainer
## Configuration d'une nouvelle partie : mode, taille de carte, difficulté, voisins, orcs et raids,
## lutins de départ, graine, faction. Chaque ligne se change d'un toucher.

signal start_requested
signal faction_requested

var _rows: VBoxContainer
var _desc: Label


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(900, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	v.add_child(UiStyle.header("Nouvelle partie", 32, func() -> void: visible = false))
	_desc = Label.new()
	_desc.add_theme_color_override("font_color", UiStyle.PARCH)
	_desc.add_theme_font_size_override("font_size", 18)
	v.add_child(_desc)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(880, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	v.add_child(bottom)
	var fb := Button.new()
	fb.text = "Faction et emblème…"
	fb.custom_minimum_size = Vector2(380, 60)
	fb.pressed.connect(func() -> void: faction_requested.emit())
	bottom.add_child(fb)
	var go := Button.new()
	go.text = "Lancer la partie"
	go.custom_minimum_size = Vector2(460, 60)
	UiStyle.make_primary(go)
	go.pressed.connect(func() -> void: start_requested.emit())
	bottom.add_child(go)
	refresh()


var advanced: bool = false


func refresh() -> void:
	for c in _rows.get_children():
		c.queue_free()
	var cfg := DataRegistry.get_table("difficulty")
	var modes: Array = cfg.get("modes", []).filter(func(m: Dictionary) -> bool: return not m.get("hidden", false))
	_row("Mode", _name_of(modes, GameSetup.mode), func() -> void: GameSetup.set_mode(_next_id(modes, GameSetup.mode)))
	for m: Dictionary in modes:
		if m["id"] == GameSetup.mode:
			_desc.text = str(m.get("desc", ""))
	var sizes: Array = DataRegistry.get_table("world").get("sizes", [])
	var sd := GameSetup.size_def()
	_row(
		"Taille de la carte",
		"%s (%d × %d)%s" % [sd.get("name", "?"), int(sd.get("x", 0)), int(sd.get("z", 0)), _size_note()],
		func() -> void: GameSetup.map_size = _next_id(sizes, GameSetup.map_size)
	)
	var levels: Array = cfg.get("levels", [])
	_row(
		"Difficulté",
		_name_of(levels, GameSetup.difficulty),
		func() -> void: GameSetup.difficulty = _next_id(levels, GameSetup.difficulty)
	)
	_row(
		"Lutins de départ",
		str(GameSetup.lutin_count),
		func() -> void: GameSetup.lutin_count = _cycle_int(GameSetup.lutin_count, 2, 10)
	)
	var info := SaveManager.slot_info(GameSetup.save_slot)
	var slot_txt := (
		"Emplacement %s — %s"
		% [GameSetup.save_slot.trim_prefix("slot"), "libre" if info.is_empty() else "OCCUPÉ (sera remplacé)"]
	)
	_row("Sauvegarde", slot_txt, func() -> void: GameSetup.save_slot = _next_slot())
	var adv := Button.new()
	adv.text = "Paramètres avancés ▴" if advanced else "Paramètres avancés ▾"
	adv.custom_minimum_size = Vector2(860, 46)
	adv.add_theme_font_size_override("font_size", 18)
	adv.pressed.connect(
		func() -> void:
			advanced = not advanced
			refresh.call_deferred()
	)
	_rows.add_child(adv)
	if not advanced:
		return
	_row(
		"Villages voisins (IA)",
		str(GameSetup.ai_factions) if GameSetup.ai_factions > 0 else "aucun",
		func() -> void: GameSetup.ai_factions = (GameSetup.ai_factions + 1) % 4
	)
	if GameSetup.ai_factions > 0:
		_row(
			"Lutins de départ des voisins",
			str(GameSetup.ai_start_lutins),
			func() -> void: GameSetup.ai_start_lutins = _cycle_int(GameSetup.ai_start_lutins, 2, 10)
		)
	_row("Orcs", "oui" if GameSetup.orcs else "non", func() -> void: GameSetup.orcs = not GameSetup.orcs)
	if GameSetup.orcs:
		var days: Array = cfg.get("raid_days", [20, 50, 100, 200]).map(func(x: Variant) -> int: return int(x))
		_row(
			"Raids d'orcs",
			"tous les %d jours" % GameSetup.raid_days,
			func() -> void: GameSetup.raid_days = days[(days.find(GameSetup.raid_days) + 1) % days.size()]
		)
	_row("Graine de carte", str(GameSetup.seed_value), func() -> void: GameSetup.seed_value = randi() % 100000)


## Valeur suivante, en boucle (… 9, 10, 2, 3 …).
static func _cycle_int(v: int, lo: int, hi: int) -> int:
	return lo if v >= hi else v + 1


static func _next_slot() -> String:
	var slots: Array = SaveManager.SLOTS
	return slots[(slots.find(GameSetup.save_slot) + 1) % slots.size()]


func _size_note() -> String:
	return "  — création longue" if GameSetup.map_size in ["large", "huge"] else ""


func _row(label: String, value: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = "%s : %s" % [label, value]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(860, 50)
	b.add_theme_font_size_override("font_size", 21)
	b.pressed.connect(
		func() -> void:
			cb.call()
			refresh.call_deferred()
	)
	_rows.add_child(b)


static func _name_of(list: Array, id: String) -> String:
	for e: Dictionary in list:
		if e["id"] == id:
			return str(e["name"])
	return id


static func _next_id(list: Array, id: String) -> String:
	for i in list.size():
		if list[i]["id"] == id:
			return str(list[(i + 1) % list.size()]["id"])
	return str(list[0]["id"])
