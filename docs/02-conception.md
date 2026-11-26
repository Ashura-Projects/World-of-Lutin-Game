# 02 — Document de conception (source de vérité)

> Chiffres = points de départ, ils vivent dans `data/*.json`. **[À VALIDER]** = décision d'Ashura attendue.

# PHASE 1 — MODE BAC À SABLE

## 1. Le monde
- Monde en **blocs de 1 unité**. Carte MVP : 128 × 128 × 48 de haut (256 × 256 ensuite).
- Génération procédurale seedée, terre ferme : **plaines, forêts, rivière, lac, montagne, collines**, gisements dans la roche.
- Blocs naturels : herbe, terre, terre fertile, sable, argile, pierre, minerai de fer, charbon, eau (fixe), neige (sommets).
- Tout bloc naturel peut être **creusé** (récolte) sauf l'eau et le socle du fond.
- **Végétation** (objets, pas des blocs) : arbres (chêne, pin, bouleau), buissons à baies, roseaux.
- **Faune** : cerfs, sangliers (chasse), poissons dans la rivière/lac (pêche).
- **Temps** : 1 jour = 6 min à x1 ; 4 saisons × 5 jours. L'hiver : pas de culture, neige, besoin de bois de chauffe.

## 2. Les Lutins
- Petites créatures **bleues**, environ 1 bloc de haut. Départ : **6 lutins** + un chariot de vivres et d'outils.
- Fiche : nom, **métier**, niveau d'expérience du métier, besoins.
- **Besoins** : faim, sommeil, chaleur (hiver), moral. Moral bas → travail lent ; très bas → il quitte le village.
- **Déplacement** : marche, monte une marche d'**1 bloc**, ne saute pas plus ; escaliers, échelles et ponts à construire pour le reste.
- Nouveaux lutins : arrivent si le village est attractif (nourriture, lits libres, moral) **[À VALIDER : ou bien naissances ?]**.

## 3. Métiers
- **Proposition** : le métier dépend de **l'outil** que le lutin porte (hache = bûcheron, pioche = mineur…). Pour changer de métier, on lui donne un autre outil depuis la réserve. Les outils se fabriquent → l'économie contrôle la main-d'œuvre. **[À VALIDER]**
- Métiers Phase 1 : voir `data/jobs.json` — porteur (sans outil), bûcheron, mineur, bâtisseur, cueilleur, pêcheur, chasseur, fermier, menuisier, tailleur de pierre, forgeron, boulanger/cuisinier.
- Les lutins gagnent de l'**expérience** dans leur métier → travaillent plus vite.

## 4. Récolte (même logique que Castle Story)
- Le joueur **désigne** : arbres à couper (tap ou zone), blocs à creuser (zone en 3D), buissons à cueillir.
- Désigner = des ordres sur un **tableau de tâches** ; les lutins du bon métier les prennent d'eux-mêmes.
- Pêche : poste de pêche au bord de l'eau. Chasse : zone de chasse.
- Ressources **physiques** : elles tombent au sol, les porteurs les ramènent en **réserve**.

## 5. Construction (le cœur)
### Pose au doigt « à la Minecraft »
- **Tap sur la face d'un bloc** → un **bloc-plan** (fantôme bleu) apparaît collé à cette face.
- Choix du matériau dans la barre (bois, planche, pierre, pierre taillée, brique, chaume…).
- **Glisser** depuis une face → ligne de blocs ; mode **remplir** (rectangle) ; mode **mur** (hauteur réglable).
- **Retirer** : outil gomme (plan annulé, ou bloc construit marqué « à démolir »).
- **Curseur d'étage** : masque tout ce qui est au-dessus d'un niveau pour voir et construire à l'intérieur.
- **Gabarits** (plus tard) : tour, rempart, escalier, maison — enregistrables par le joueur.

### Ce sont les lutins qui bâtissent
- Les plans créent des tâches : les porteurs apportent les blocs, les **bâtisseurs** les posent.
- Règle de solidité Phase 1 (simple) : un bloc doit toucher un autre bloc solide. Pas d'effondrement en Phase 1.

### Objets et pièces
- **Objets** placés sur les blocs : lit, foyer, table, coffre, étagère, établis, porte, fenêtre, torche, échelle.
- Un volume **fermé** (murs + toit) = une **pièce**, typée selon ses objets (`data/rooms.json`) : maison, dortoir, atelier, cuisine, réserve.
- Une pièce chauffée et meublée donne du moral et protège du froid.

## 6. Agriculture
- **Champs** tracés sur terre fertile ; cultures : blé, légumes, lin. Semis au printemps, récolte en été/automne.
- Rendement selon fertilité, saison, fermier. **[Plus tard]** élevage : moutons (laine), poules (œufs).

## 7. Production (chaînes)
- Sur des **établis** avec liste de commandes (« faire 20 planches », « garder 50 pains en stock »).
- Bois → planches ; pierre → pierre taillée ; argile → briques ; blé → farine → pain ; minerai + charbon → lingot → outils ;
  lin → tissu → vêtements ; poisson/viande → repas.
- Bonus si l'établi est dans une pièce du bon type (atelier, cuisine).

## 8. Gestion et objectifs (partie longue)
- Tableau de bord : stocks, production/consommation par jour, lutins, moral, alertes (famine, froid, plus d'outils).
- **Rangs** : Campement → Hameau → Village → Bourg. Chaque rang débloque matériaux, objets, métiers.
- Objectifs facultatifs proposés au fil de la partie (« construire une tour de 20 blocs », « nourrir 30 lutins un hiver »).

# PHASE 2 — MODE AVENTURE ROYALE (à détailler après la Phase 1)
- Départ avec **3 à 4 lutins**, un roi/une reine lutin à protéger.
- **Orcs** rouges grassouillets : camps sur la carte, raids nocturnes, sièges avec béliers et échelles.
- Combat : métiers guerrier / archer (outil = arme), ordres de groupe, défense par étages, créneaux.
- **Destruction et effondrement** des blocs non soutenus (sièges spectaculaires).
- **Carte régionale** : autres royaumes lutins (IA), tribus orques, provinces à prendre.
- **Diplomatie** : émissaires, alliances, tributs, commerce, déclarations de guerre.
- But de partie : unifier la région / devenir Haut-Roi. **[À VALIDER]**

## Questions ouvertes
1. Métier = outil porté (comme proposé) : OK ?
2. Nouveaux lutins : arrivées ou naissances ?
3. Nom définitif du jeu.
4. Carte aléatoire, ou aussi des cartes dessinées à la main ?
