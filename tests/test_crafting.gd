extends GutTest
## La liste de fabrication est complète et cohérente : tout s'obtient, chaque atelier et métier existe.


func _resources() -> Dictionary:
	var out := {}
	for r: Dictionary in DataRegistry.get_table("resources")["resources"]:
		out[r["id"]] = r
	return out


## Ressources obtenues sans fabrication : récolte, creusage, chasse, pêche, cultures, chariot.
func _natural() -> Dictionary:
	var out := {}
	for b: Dictionary in DataRegistry.get_table("blocks")["blocks"]:
		for k: String in b.get("drop", {}):
			out[k] = true
	var flora := DataRegistry.get_table("flora")
	for t: Dictionary in flora["trees"].values():
		for k: String in t["drop"]:
			out[k] = true
	for k: String in flora["bush"]["drop"]:
		out[k] = true
	for k: String in flora["fishing"]["drop"]:
		out[k] = true
	for a: Dictionary in DataRegistry.get_table("animals")["animals"]:
		for k: String in a.get("drop", {}):
			out[k] = true
	var crops := DataRegistry.get_table("crops")
	for c: Dictionary in crops["crops"]:
		for k: String in c["yield"]:
			out[k] = true
	for w: Dictionary in crops["wild"]:
		for k: String in w["gather"]:
			out[k] = true
	for k: String in DataRegistry.get_table("start")["cart"]["fixed"]:
		out[k] = true
	return out


func test_chaque_ingredient_s_obtient() -> void:
	var res := _resources()
	var obtainable := _natural()
	for r: Dictionary in DataRegistry.get_table("recipes")["recipes"]:
		for k: String in r.get("out", {}):
			obtainable[k] = true
	for r: Dictionary in DataRegistry.get_table("recipes")["recipes"]:
		for k: String in r.get("in", {}):
			assert_true(res.has(k), "%s : ressource inconnue %s" % [r["id"], k])
			assert_true(obtainable.has(k), "%s : %s ne s'obtient nulle part" % [r["id"], k])
		for k: String in r.get("out", {}):
			assert_true(res.has(k), "%s : produit inconnu %s" % [r["id"], k])
	for b: Dictionary in DataRegistry.get_table("buildings")["buildings"]:
		for k: String in b.get("cost", {}):
			assert_true(obtainable.has(k), "%s coûte %s, introuvable" % [b["id"], k])


func test_ateliers_et_metiers_existent() -> void:
	var stations := {}
	for b: Dictionary in DataRegistry.get_table("buildings")["buildings"]:
		if b.has("station"):
			stations[b["station"]] = true
	var jobs := {}
	for j: Dictionary in DataRegistry.get_table("jobs")["jobs"]:
		jobs[j["id"]] = true
	for r: Dictionary in DataRegistry.get_table("recipes")["recipes"]:
		assert_true(stations.has(r["station"]), "%s : atelier %s absent" % [r["id"], r["station"]])
		assert_true(jobs.has(r["job"]), "%s : métier %s absent" % [r["id"], r["job"]])


func test_chaque_outil_se_fabrique() -> void:
	var made := {}
	for r: Dictionary in DataRegistry.get_table("recipes")["recipes"]:
		for k: String in r.get("out", {}):
			made[k] = true
	for j: Dictionary in DataRegistry.get_table("jobs")["jobs"]:
		if j.get("tool") != null:
			assert_true(made.has(j["tool"]), "l'outil %s (%s) ne se fabrique pas" % [j["tool"], j["id"]])


func test_liste_bien_fournie() -> void:
	assert_gte(DataRegistry.get_table("recipes")["recipes"].size(), 60)
	var furniture := _resources().values().filter(func(r: Dictionary) -> bool: return r["category"] == "furniture")
	assert_gte(furniture.size(), 12, "meubles et décorations")
