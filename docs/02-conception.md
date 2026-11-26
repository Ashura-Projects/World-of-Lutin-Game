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
- **Les lutins naissent** (validé) : voir §2b.

## 2b. Cycle de vie
- **Naissance** : un couple de lutins adultes dans une **maison** avec un lit libre, village nourri et moral correct → chance de naissance (`data/population.json`).
- **Âges** : bébé → **enfant** → adulte → ancien. Un enfant ne travaille pas : il joue, mange et **va à l'école**.
- Ce que l'enfant apprend décide de ce qu'il pourra devenir (§3b).
- **[À VALIDER]** Les anciens meurent-ils de vieillesse (cimetière, héritage de savoir) ou restent-ils indéfiniment ?

## 3. Métiers
- **Validé** : le métier de base dépend de **l'outil** porté (hache = bûcheron, pioche = mineur…). Les outils se fabriquent → l'économie contrôle la main-d'œuvre.
- Métiers de base : voir `data/jobs.json` — porteur (sans outil), bûcheron, mineur, bâtisseur, cueilleur, pêcheur, chasseur, fermier, menuisier, tailleur de pierre, forgeron, cuisinier.
- Les lutins gagnent de l'**expérience** dans leur métier → travaillent plus vite.

### Panneau d'affectation (gestion automatisée)
- Chaque **bâtiment de travail** (atelier, scierie, ferme, mine, cuisine, école…) a des **postes** (nombre de places).
- **Panneau d'affectation** : liste des bâtiments × lutins, on **attribue un lutin à un bâtiment** d'un tap (ou glisser-déposer).
- Un lutin affecté : récupère **automatiquement** l'outil adapté en réserve, travaille dans ce bâtiment en priorité, y retourne chaque jour.
- Mode « auto » par bâtiment : le jeu remplit les postes vides avec les lutins libres les plus compétents.
- Les lutins non affectés font les tâches générales (porter, récolter les zones désignées, bâtir).
- Alertes : « Scierie : 1 poste vide », « Pas de hache en réserve pour le bûcheron affecté ».

## 3b. Éducation, formation et recherche
- **École** (bâtiment, avec un **maître** affecté) : les enfants y vont le jour ; ils accumulent des **aptitudes** (savoir, force, adresse, magie) selon les cours choisis.
- À l'âge adulte, les aptitudes ouvrent l'accès aux **centres de formation** :
  | Centre | Forme des | Rôle |
  |---|---|---|
  | **Bibliothèque / académie** | **Chercheurs** | produisent des points de recherche → débloquent les **technologies** |
  | **Atelier de maître** | Artisans experts | recettes avancées, meilleure qualité |
  | **Caserne** *(Phase 2)* | **Soldats** (guerrier, archer) | défense, guerre |
  | **Tour des mages** *(Phase 2)* | **Mages** | **[À VALIDER : que fait la magie ?]** (soin, protection des remparts, météo, combat…) |
- Les métiers spécialisés ne s'obtiennent **que par l'éducation** (pas par un simple outil).
- Un adulte non formé peut suivre une formation courte (moins efficace qu'un enfant éduqué).

### Technologies (Phase 1 : arbre court)
- Les chercheurs accumulent des points ; le joueur choisit la prochaine technologie (`data/technologies.json`).
- Exemples : charrue (rendement agricole), moulin (farine plus rapide), maçonnerie (pierre taillée, tours), fours à briques, fer forgé (outils durables), écriture (école améliorée).
- Phase 2 : technologies militaires et magiques.

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
- Combat : **soldats** (guerrier, archer) et **mages** formés à la caserne / tour des mages (§3b), ordres de groupe, défense par étages, créneaux.
- **Destruction et effondrement** des blocs non soutenus (sièges spectaculaires).
- **Carte régionale** : autres royaumes lutins (IA), tribus orques, provinces à prendre.
- **Diplomatie** : émissaires, alliances, tributs, commerce, déclarations de guerre.
- But de partie : unifier la région / devenir Haut-Roi. **[À VALIDER]**

## Questions ouvertes
1. Que fait la magie des mages (soin, protection, météo, combat…) ?
2. Les anciens meurent-ils de vieillesse ?
3. Carte aléatoire, ou aussi des cartes dessinées à la main ?
