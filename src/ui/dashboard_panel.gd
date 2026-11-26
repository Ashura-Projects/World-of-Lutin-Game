class_name DashboardPanel
extends PanelContainer
## Tableau de bord : rang du village, population et moral, bilan d'hier (production / consommation), alertes, objectifs.

var game: Node
var _body: Label


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(820, 0)
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(UiStyle.title_label("Tableau de bord", 30))
	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 19)
	v.add_child(_body)


func refresh() -> void:
	var vil: Village = game.sim.village
	var c: Colony = game.colony
	var mood := 0.0
	for l in c.lutins:
		mood += float(l.needs["mood"])
	mood /= maxf(1.0, c.lutins.size())
	var lines := ["Rang : %s   ·   %d lutins   ·   moral moyen %d" % [vil.rank_name(), c.lutins.size(), int(mood)], ""]
	lines.append("Hier (production − consommation) :")
	var deltas := []
	for id: String in vil.daily_delta:
		if int(vil.daily_delta[id]) != 0:
			deltas.append("%s %+d" % [Stockpile._resource(id).get("name", id), int(vil.daily_delta[id])])
	lines.append("  " + (", ".join(deltas) if not deltas.is_empty() else "pas encore de bilan"))
	lines.append("")
	lines.append("Alertes : " + ("; ".join(vil.alerts) if not vil.alerts.is_empty() else "aucune"))
	lines.append("")
	lines.append("Objectifs :")
	for o: Dictionary in DataRegistry.get_table("objectives").get("objectives", []):
		lines.append("  %s %s" % ["✓" if vil.done.has(o["id"]) else "○", o["name"]])
	_body.text = "\n".join(lines)
