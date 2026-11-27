class_name NpcLook
extends RefCounted
## Apparence des lutins des autres factions : même modèle que nos lutins, peau jaune, rouge ou vert clair,
## tenue de la faction ; les soldats portent l'uniforme (casque, baudriers) aux couleurs de leur faction.


static func is_npc(kind: String) -> bool:
	return (
		kind.begins_with("villager_")
		or kind.begins_with("soldier_")
		or kind.begins_with("preacher_")
		or kind.begins_with("bandit")
	)


static func build(kind: String) -> Node3D:
	if kind.begins_with("bandit"):  # bandits : lutins gris, capuche et haillons sombres
		var b := LutinModel.new()
		b.skin_override = "9a9a9e"
		b.tunic_override = "3a3a40"
		b.build("scout")
		return b
	var parts := kind.split("_")
	var fd := Rivals.def(parts[1]) if parts.size() > 1 else {}
	var m := LutinModel.new()
	m.skin_override = str(fd.get("skin", "466ca0"))
	var soldier := parts[0] == "soldier"
	m.tunic_override = str(fd.get("color", "888888")) if soldier else str(fd.get("tunic", "6a5a48"))
	m.build("militia" if soldier else ("farmer" if parts[0] == "villager" else "hauler"))
	return m
