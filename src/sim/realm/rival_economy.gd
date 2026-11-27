class_name RivalEconomy
extends RefCounted
## Économie des villages IA (1.4.1). Chaque jour, la population se répartit en métiers (fermiers, bûcherons,
## mineurs, artisans, bâtisseurs ; les soldats à part) selon le caractère de la faction ; chaque métier produit
## (vivres, bois, pierre, fer, marchandises) avec un bonus par bâtiment et par niveau d'amélioration ; la population
## mange ; les marchandises se vendent (or). Famine : la population baisse ; abondance : elle grandit plus vite.
## Les bâtiments coûtent de l'or ET des matériaux ; quand le plan est fini, l'IA améliore ses bâtiments (niveaux).
## Données : data/factions.json › economy.

const JOB_NAMES := {
	"farmer": "fermiers",
	"woodcutter": "bûcherons",
	"miner": "mineurs",
	"artisan": "artisans",
	"builder": "bâtisseurs",
	"soldier": "soldats"
}
const RES_NAMES := {"food": "vivres", "wood": "bois", "stone": "pierre", "iron": "fer", "goods": "marchandises"}


static func cfg() -> Dictionary:
	return DataRegistry.get_table("factions").get("economy", {})


## Répartit les habitants (hors soldats) entre les métiers, selon les poids de la faction.
static func assign_jobs(st: Dictionary) -> void:
	var fd := Rivals.def(st["id"])
	var weights: Dictionary = cfg().get("job_weights", {}).duplicate()
	for k: String in fd.get("job_bias", {}):
		weights[k] = float(weights.get(k, 1.0)) * float(fd["job_bias"][k])
	var workers := maxi(0, int(st["population"]) - int(st["soldiers"]))
	var total := 0.0
	for k: String in weights:
		total += float(weights[k])
	var jobs := {}
	var given := 0
	for k: String in weights:
		var n := int(floor(workers * float(weights[k]) / maxf(0.001, total)))
		jobs[k] = n
		given += n
	if workers - given > 0:
		jobs["farmer"] = int(jobs.get("farmer", 0)) + workers - given  # le reste aux champs
	jobs["soldier"] = int(st["soldiers"])
	st["jobs"] = jobs


## Production et consommation du jour.
static func daily(st: Dictionary) -> void:
	assign_jobs(st)
	var c := cfg()
	var stock: Dictionary = st.get_or_add(
		"stock", {"food": 20.0, "wood": 10.0, "stone": 5.0, "iron": 0.0, "goods": 0.0}
	)
	var per: Dictionary = c.get("per_worker", {})
	for job: String in per:
		var n := int(st["jobs"].get(job, 0))
		var out: Dictionary = per[job]
		for res: String in out:
			var mult := 1.0 + RivalBuilder.effect(st, res + "_bonus")
			stock[res] = float(stock.get(res, 0.0)) + n * float(out[res]) * mult
	# artisans : bois + fer -> marchandises (si matières)
	var art := int(st["jobs"].get("artisan", 0))
	var need := float(c.get("artisan_wood", 0.5)) * art
	if float(stock.get("wood", 0.0)) >= need:
		stock["wood"] = float(stock["wood"]) - need
		stock["goods"] = (
			float(stock.get("goods", 0.0))
			+ art * float(c.get("artisan_goods", 0.6)) * (1.0 + RivalBuilder.effect(st, "goods_bonus"))
		)
	# repas
	var eat := int(st["population"]) * float(c.get("food_per_pop", 0.8))
	stock["food"] = float(stock.get("food", 0.0)) - eat
	if float(stock["food"]) < 0.0:
		stock["food"] = 0.0
		if int(st["population"]) > 2 and Rng.chance(float(c.get("famine_loss_chance", 0.3))):
			st["population"] = int(st["population"]) - 1  # famine
	# vente des marchandises
	var sold := minf(float(stock.get("goods", 0.0)), float(c.get("goods_sold_per_day", 4)))
	stock["goods"] = float(stock.get("goods", 0.0)) - sold
	st["wealth"] = float(st["wealth"]) + sold * float(c.get("goods_price", 2.0))
	for res: String in stock:
		stock[res] = minf(float(stock[res]), float(c.get("stock_cap", 400)))


## Croissance en plus quand les greniers sont pleins (jours de vivres d'avance).
static func growth_bonus(st: Dictionary) -> float:
	var stock: Dictionary = st.get("stock", {})
	var days := float(stock.get("food", 0.0)) / maxf(1.0, int(st["population"]) * float(cfg().get("food_per_pop", 0.8)))
	return clampf((days - 3.0) * 0.01, 0.0, float(cfg().get("max_growth_bonus", 0.1)))


## Le bâtiment coûte-t-il trop de matériaux ? Si non, les prélève. (or : géré par RivalBuilder)
static func pay(st: Dictionary, cost: Dictionary) -> bool:
	var stock: Dictionary = st.get_or_add("stock", {})
	for k: String in cost:
		if float(stock.get(k, 0.0)) < float(cost[k]):
			return false
	for k: String in cost:
		stock[k] = float(stock[k]) - float(cost[k])
	return true


## Amélioration : le bâtiment le moins avancé monte d'un niveau (effets × niveau), si l'or et les matériaux y sont.
static func upgrade(st: Dictionary) -> String:
	var c := cfg()
	var best: Dictionary = {}
	for b: Dictionary in st.get("buildings", []):
		if (
			int(b.get("level", 1)) < int(c.get("max_level", 3))
			and (best.is_empty() or int(b.get("level", 1)) < int(best.get("level", 1)))
		):
			best = b
	if best.is_empty():
		return ""
	var lvl := int(best.get("level", 1))
	var gold := float(c.get("upgrade_gold", 40)) * lvl
	var mats: Dictionary = {}
	for k: String in c.get("upgrade_cost", {}):
		mats[k] = float(c["upgrade_cost"][k]) * lvl
	if float(st["wealth"]) < gold or not pay(st, mats):
		return ""
	st["wealth"] = float(st["wealth"]) - gold
	best["level"] = lvl + 1
	return str(best["id"])


## Résumé lisible (panneau de diplomatie) : métiers et réserves.
static func summary(st: Dictionary) -> String:
	var jobs: Dictionary = st.get("jobs", {})
	var parts := []
	for k: String in JOB_NAMES:
		if int(jobs.get(k, 0)) > 0:
			parts.append("%d %s" % [int(jobs[k]), JOB_NAMES[k]])
	var stock: Dictionary = st.get("stock", {})
	var res := []
	for k: String in RES_NAMES:
		res.append("%s %d" % [RES_NAMES[k], int(stock.get(k, 0.0))])
	var levels := 0
	for b: Dictionary in st.get("buildings", []):
		levels += int(b.get("level", 1))
	return (
		"Métiers : %s · Réserves : %s · %d bâtiment(s), %d niveau(x)"
		% [
			", ".join(parts) if not parts.is_empty() else "aucun",
			", ".join(res),
			st.get("buildings", []).size(),
			levels
		]
	)
