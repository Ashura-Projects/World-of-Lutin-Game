class_name Kinship
extends RefCounted
## Liens de famille (parents, enfants, frères et sœurs, conjoint) à partir des parents de chaque lutin.


static func parents_of(colony: Colony, l: Lutin) -> Array:
	var out := []
	for id in l.parents:
		var p := colony.find_lutin(int(id))
		if p != null:
			out.append(p)
	return out


static func children_of(colony: Colony, l: Lutin) -> Array:
	return colony.lutins.filter(func(c: Lutin) -> bool: return c.parents.has(l.id))


static func siblings_of(colony: Colony, l: Lutin) -> Array:
	if l.parents.is_empty():
		return []
	return colony.lutins.filter(
		func(c: Lutin) -> bool: return c != l and c.parents.any(func(p: int) -> bool: return l.parents.has(p))
	)


## Parents, enfants, frères et sœurs : pas de mariage entre eux.
static func close_kin(colony: Colony, a: Lutin, b: Lutin) -> bool:
	if a.parents.has(b.id) or b.parents.has(a.id):
		return true
	return a.parents.any(func(p: int) -> bool: return b.parents.has(p))


## Conjoint : le mari ou la femme, sinon l'autre parent d'un enfant commun.
static func partner_of(colony: Colony, l: Lutin) -> Lutin:
	if l.spouse >= 0 and colony.find_lutin(l.spouse) != null:
		return colony.find_lutin(l.spouse)
	for c: Lutin in children_of(colony, l):
		for p in c.parents:
			if int(p) != l.id:
				var o := colony.find_lutin(int(p))
				if o != null:
					return o
	return null


## Résumé lisible : « Conjoint : X · Parents : … · Enfants : … · Frères et sœurs : … ».
static func summary(colony: Colony, l: Lutin) -> String:
	var parts := []
	var partner := partner_of(colony, l)
	if partner != null:
		parts.append("Conjoint : %s" % partner.name)
	for e: Array in [
		["Parents", parents_of(colony, l)],
		["Enfants", children_of(colony, l)],
		["Frères et sœurs", siblings_of(colony, l)]
	]:
		if not e[1].is_empty():
			parts.append("%s : %s" % [e[0], ", ".join(e[1].map(func(x: Lutin) -> String: return x.name))])
	return " · ".join(parts) if not parts.is_empty() else "Pas de famille au village."
