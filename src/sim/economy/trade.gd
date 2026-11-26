class_name Trade
extends RefCounted
## Commerce : un marchand ambulant passe régulièrement ; on lui vend nos surplus et on achète ce qui manque, en or.

signal merchant_arrived
signal merchant_left

var colony: Colony
var present: bool = false
var leaves_day: int = 0
var next_day: int = 0
var offers: Dictionary = {}  # ressource -> quantité proposée
var _cfg: Dictionary


func _init(c: Colony) -> void:
	colony = c
	_cfg = DataRegistry.get_table("trade")
	next_day = int(_cfg.get("visit_every_days", 4))


func price(id: String) -> int:
	return int(_cfg.get("prices", {}).get(id, 0))


func buy_price(id: String) -> int:
	var b: float = Realm.active.trade_bonus() if Realm.active != null else 0.0
	return maxi(1, ceili(price(id) * float(_cfg.get("buy_markup", 1.5)) * (1.0 - b)))


func sell_price(id: String) -> int:
	var b: float = Realm.active.trade_bonus() if Realm.active != null else 0.0
	return maxi(0, floori(price(id) * float(_cfg.get("sell_ratio", 0.7)) * (1.0 + b)))


func daily(day: int) -> void:
	if present and day >= leaves_day:
		present = false
		offers.clear()
		next_day = day + int(_cfg.get("visit_every_days", 4))
		merchant_left.emit()
		EventBus.alert.emit("commerce", "Le marchand reprend la route.")
	elif not present and day >= next_day:
		_arrive(day)


func _arrive(day: int) -> void:
	present = true
	leaves_day = day + int(_cfg.get("stay_days", 1))
	offers.clear()
	var ids: Array = _cfg.get("prices", {}).keys()
	var cnt: Array = _cfg.get("offers_count", [6, 9])
	var qty: Array = _cfg.get("offer_qty", [4, 15])
	for id: String in _cfg.get("always_offer", []):
		offers[id] = Rng.randi_range(int(qty[0]), int(qty[1]))
	for _i in Rng.randi_range(int(cnt[0]), int(cnt[1])):
		offers[ids[Rng.randi_range(0, ids.size() - 1)]] = Rng.randi_range(int(qty[0]), int(qty[1]))
	merchant_arrived.emit()
	EventBus.alert.emit("commerce", "Un marchand arrive au village !")


## Acheter n unités ; renvoie le nombre réellement acheté (or et stock du marchand limitent).
func buy(id: String, n: int) -> int:
	if not present:
		return 0
	var p := buy_price(id)
	var can := mini(n, int(offers.get(id, 0)))
	can = mini(can, colony.stock.count("gold") / p) if p > 0 else can
	if can <= 0:
		return 0
	colony.stock.take("gold", can * p)
	colony.stock.add(id, can)
	offers[id] = int(offers[id]) - can
	return can


func sell(id: String, n: int) -> int:
	if not present or sell_price(id) <= 0:
		return 0
	var got := colony.stock.take(id, n)
	colony.stock.add("gold", got * sell_price(id))
	return got


func to_dict() -> Dictionary:
	return {"present": present, "leaves": leaves_day, "next": next_day, "offers": offers}


func from_dict(d: Dictionary) -> void:
	present = bool(d.get("present", false))
	leaves_day = int(d.get("leaves", 0))
	next_day = int(d.get("next", 4))
	offers = {}
	var o: Dictionary = d.get("offers", {})
	for k: String in o:
		offers[k] = int(o[k])
