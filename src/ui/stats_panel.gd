class_name StatsPanel
extends PanelContainer
## Statistiques (1.4) : onglet Royaume (population, âges, métiers, vivres, réserve, armée, foi, humeur, territoire)
## et onglet Lutins (chaque lutin : métier, aptitudes dont le charisme, entraînement, compétences, combats) avec
## l'inscription aux cours du soir de l'école pour les adultes.

const APT := {"knowledge": "Sav", "strength": "For", "dexterity": "Dex", "charisma": "Cha"}
const APT_NAMES := {"knowledge": "savoir", "strength": "force", "dexterity": "adresse", "charisma": "charisme"}

var game: Node
var tab: String = "realm"
var _body: VBoxContainer
var _tabs: Dictionary = {}


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(1100, 0)
	var v := VBoxContainer.new()
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	v.add_child(head)
	var t := UiStyle.title_label("Statistiques", 28)
	t.custom_minimum_size = Vector2(260, 0)
	head.add_child(t)
	for e: Array in [["realm", "Royaume"], ["lutins", "Lutins"]]:
		var b := Button.new()
		b.text = e[1]
		b.custom_minimum_size = Vector2(170, 48)
		b.pressed.connect(show_tab.bind(str(e[0])))
		head.add_child(b)
		_tabs[e[0]] = b
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1080, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)


func refresh() -> void:
	show_tab(tab)


func show_tab(t: String) -> void:
	tab = t
	for k: String in _tabs:
		_tabs[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == t else UiStyle.IRON_L))
	for c in _body.get_children():
		c.queue_free()
	if t == "realm":
		_realm()
	else:
		_lutins()


func _label(text: String, size: int = 18, c: Color = UiStyle.TXT) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(1060, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	_body.add_child(l)


## Barre horizontale « nom ▮▮▮▮ valeur » (petit graphique sans bibliothèque).
func _bar(name: String, value: float, max_v: float, txt: String, col: Color = UiStyle.GOLD) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = name
	l.custom_minimum_size = Vector2(260, 0)
	row.add_child(l)
	var b := ProgressBar.new()
	b.max_value = maxf(1.0, max_v)
	b.value = value
	b.show_percentage = false
	b.custom_minimum_size = Vector2(500, 20)
	var f := StyleBoxFlat.new()
	f.bg_color = col
	b.add_theme_stylebox_override("fill", f)
	row.add_child(b)
	var v := Label.new()
	v.text = "  " + txt
	row.add_child(v)
	_body.add_child(row)


func _realm() -> void:
	var col: Colony = game.colony
	var sim: GameSim = game.sim
	var n := col.lutins.size()
	var ages := {}
	var jobs := {}
	var mood := 0.0
	var faith := 0.0
	for l: Lutin in col.lutins:
		ages[l.age_stage()] = int(ages.get(l.age_stage(), 0)) + 1
		jobs[l.job] = int(jobs.get(l.job, 0)) + 1
		mood += float(l.needs.get("mood", 70))
		faith += l.faith
	_label("Population : %d lutins" % n, 22, UiStyle.GOLD)
	for a: String in ["baby", "child", "adult", "elder"]:
		var nm: String = {"baby": "Bébés", "child": "Enfants", "adult": "Adultes", "elder": "Anciens"}[a]
		_bar(nm, int(ages.get(a, 0)), n, str(int(ages.get(a, 0))))
	_bar("Humeur moyenne", mood / maxf(1, n), 100, "%d %%" % int(mood / maxf(1, n)), Color("8ac060"))
	_bar("Foi moyenne", faith / maxf(1, n), 100, "%d %%" % int(faith / maxf(1, n)), Color("c8a0e0"))
	_bar(
		"Réserve de vivres", sim.population.food_days(), 30, "%.1f jours" % sim.population.food_days(), Color("d0a040")
	)
	_label("Métiers", 22, UiStyle.GOLD)
	var keys := jobs.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return int(jobs[a]) > int(jobs[b]))
	for j: String in keys:
		_bar(LutinSheet.job_name(j), int(jobs[j]), n, str(int(jobs[j])), Color("6a8ac0"))
	_label("Armée", 22, UiStyle.GOLD)
	var soldiers := col.lutins.filter(func(l: Lutin) -> bool: return l.job == "soldier" or l.unit_id >= 0).size()
	var kills := 0
	for l: Lutin in col.lutins:
		for k: String in l.kills:
			kills += int(l.kills[k])
	_label(
		(
			"Soldats et membres d'unités : %d · Unités : %d · Ennemis et bêtes abattus : %d"
			% [soldiers, sim.units.units.size(), kills]
		),
		18
	)
	_label("Royaume", 22, UiStyle.GOLD)
	_label(
		(
			"Or : %d · Territoire : %d zones · Bâtiments et objets : %d · Voisins rencontrés : %d"
			% [
				col.stock.count("gold"),
				sim.territory.count("player"),
				sim.structures.items.size(),
				sim.realm.neighbours().size()
			]
		),
		18
	)
	_label("Réserve (les plus grosses quantités)", 22, UiStyle.GOLD)
	var items: Array = col.stock.items.keys()
	items.sort_custom(func(a: String, b: String) -> bool: return col.stock.count(a) > col.stock.count(b))
	var top := col.stock.count(items[0]) if not items.is_empty() else 1
	for i in mini(10, items.size()):
		var k: String = items[i]
		_bar(
			str(Stockpile._resource(k).get("name", k)),
			col.stock.count(k),
			top,
			str(col.stock.count(k)),
			Color("a08a60")
		)


func _lutins() -> void:
	var edu: Education = game.sim.education
	_label(
		(
			"Sav = savoir, For = force, Dex = adresse, Cha = charisme (0 à 100) · F/A/R = entraînement · Cmd/Dip = "
			+ "Commandement / Diplomatie. Cours du soir : un adulte inscrit progresse chaque jour où le maître enseigne."
		),
		16,
		UiStyle.TXT_D
	)
	for l: Lutin in game.colony.lutins:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_body.add_child(row)
		var apt := []
		for k: String in APT:
			apt.append("%s %d" % [APT[k], int(l.aptitudes.get(k, 0))])
		var kills := 0
		for k: String in l.kills:
			kills += int(l.kills[k])
		var lab := Label.new()
		lab.text = (
			"%s (%d a.) · %s %d · %s · F%d A%d R%d · Cmd %d Dip %d · %d abattus"
			% [
				l.name,
				l.age_days / 20,
				LutinSheet.job_name(l.job),
				l.job_level(),
				" ".join(apt),
				Soldiering.drill_level(l, "force"),
				Soldiering.drill_level(l, "agility"),
				Soldiering.drill_level(l, "robust"),
				Soldiering.skill_level(l, "command"),
				Soldiering.skill_level(l, "diplomacy"),
				kills
			]
		)
		lab.custom_minimum_size = Vector2(840, 0)
		lab.add_theme_font_size_override("font_size", 15)
		row.add_child(lab)
		if l.age_stage() != "adult":
			continue
		var o := OptionButton.new()
		o.custom_minimum_size = Vector2(200, 40)
		o.add_item("Cours : aucun")
		for k: String in APT_NAMES:
			o.add_item("Cours : " + str(APT_NAMES[k]))
			if str(edu.adult_students.get(l.id, "")) == k:
				o.select(o.item_count - 1)
		o.item_selected.connect(
			func(i: int) -> void:
				var k2: String = "" if i == 0 else str(APT_NAMES.keys()[i - 1])
				if not edu.study(l, k2):
					EventBus.alert.emit("alerte", "Plus de place aux cours du soir.")
		)
		row.add_child(o)
