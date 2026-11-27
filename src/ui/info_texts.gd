class_name InfoTexts
extends RefCounted
## Textes d'aide des boutons « Info » (accueil et partie).


static func title_help() -> String:
	return (
		"Jouer › Continuer reprend la dernière partie ; Nouvelle partie choisit le mode, la carte\n"
		+ "et l'emplacement (5 au choix) ; Charger liste les parties (supprimer : deux touchers) ;\n"
		+ "Tutoriel apprend à construire, cultiver et se défendre, mission par mission.\n"
		+ "↩ Retour revient toujours à l'écran précédent."
	)


static func game_help(context: String) -> String:
	var tips := {
		"build":
		(
			"Construire : choisissez une catégorie puis un élément ; « Forme » change escaliers, demi-blocs,\n"
			+ "pentes, arrondis ; « Sens » les tourne. Le menu se réduit en bulle : touchez la carte pour poser."
		),
		"orders":
		"Ordres : touchez un arbre, une plante, un animal ou le sol ; Explorer, Base, Cheval.\n✕ quitte le mode ordres.",
		"zones": "Zones : touchez des cases (ou 2 coins en Rectangle) pour l'aperçu, puis « Valider les champs ».",
	}
	return tips.get(
		context,
		(
			"Touchez un lutin pour lui donner des ordres, un animal ou un objet pour sa fiche.\n"
			+ "Les menus du bas ouvrent les fenêtres ; ↩ Retour ferme la dernière ouverte.\n"
			+ "Carte : vue d'ensemble, brouillard, marqueurs. ⚙ : sauvegarde et paramètres."
		)
	)
