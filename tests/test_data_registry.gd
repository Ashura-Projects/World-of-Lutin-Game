extends GutTest


func test_tables_chargees() -> void:
	for name in ["blocks", "jobs", "resources", "recipes", "time", "world", "crops", "animals", "start"]:
		assert_false(DataRegistry.get_table(name).is_empty(), "table " + name)


func test_index_blocs() -> void:
	assert_eq(DataRegistry.block_num("air"), 0)
	assert_eq(DataRegistry.block(DataRegistry.block_num("stone"))["id"], "stone")


func test_numeros_de_blocs_uniques() -> void:
	var seen := {}
	for b: Dictionary in DataRegistry.get_table("blocks")["blocks"]:
		assert_false(seen.has(b["num"]), "doublon %s" % b["num"])
		seen[b["num"]] = true
		assert_lt(int(b["num"]), 256, "un bloc tient sur un octet")


func test_outils_des_metiers_existent() -> void:
	var tools := {}
	for r: Dictionary in DataRegistry.get_table("resources")["resources"]:
		tools[r["id"]] = true
	for j: Dictionary in DataRegistry.get_table("jobs")["jobs"]:
		if j.get("tool") != null:
			assert_true(tools.has(j["tool"]), "outil manquant : %s" % j["tool"])
