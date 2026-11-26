# 02 — Document de conception (source de vérité)

> Chiffres = points de départ, ils vivent dans `data/*.json`. **[À VALIDER]** = décision d'Ashura attendue.

# PHASE 1 — MODE BAC À SABLE

## 1. Le monde
- Monde en **blocs de 1 unité**. **Validé : grande carte** pour bâtir librement (châteaux comme petites maisons) :
  **256 × 256 × 64** par défaut, 128 × 128 au choix (`data/world.json`). **[À VALIDER : tenue des 60 FPS à mesurer au J1]**
- **Carte vierge** au départ : aucune construction, juste le chariot des lutins.
- Génération seedée : **grande plaine**, **forêts**, **rivière** (et lac), **collines** riches en minerais, **montagne à explorer**.
- **Couches comme Minecraft** : herbe → terre (2-4) → pierre → roche profonde → socle. Poches de gravier, d'argile (près de l'eau),
  de **charbon** et de **fer** dans la pierre. On creuse **bloc par bloc** : trous, galeries, mines, **puits** (jusqu'à la nappe d'eau).
- **Validé — ordre de creusage simple** : on pose un rectangle, puis des boutons **+ / −** règlent **largeur**, **longueur** et **profondeur**.
  Puits = raccourci 1×1 jusqu'à la nappe.
- Blocs naturels : herbe, terre, terre fertile, sable, gravier, argile, pierre, roche profonde, minerai de fer, charbon, eau (fixe), neige (sommets).
- Tout bloc naturel peut être **creusé** (récolte) sauf l'eau et le socle du fond.
- **Végétation** (objets, pas des blocs) : arbres (plusieurs espèces pour le décor), buissons à baies, roseaux, **lin sauvage**.
- **Un seul bois** : la **bûche**, quel que soit l'arbre. Elle se transforme en **planches** ou en **poutres**, matériaux des blocs.
- **Faune** : **cerfs** et **sangliers** (viande + **peaux**), poissons dans la rivière/lac (pêche). `data/animals.json`.
- **Validé — premiers ennemis dès le Bac à sable : loup** (en meute, la nuit) et **ours** (seul, très solide).
  PV, dégâts, portée et cadence **fixes et réalistes** (loup 40 PV / 8 dégâts / 1,2 bloc ; ours 150 PV / 22 dégâts / 1,6 bloc).
  Les tuer donne de l'**XP de combat** (premiers guerriers). Les **lutins ont des PV et des stats d'attaque** (`population.json` › combat).
  Armes dès la Phase 1 : lance et fusil à silex ; armures et uniformes en Phase 2.
- **Temps** : 1 jour = 6 min à x1 ; 4 saisons × 5 jours. L'hiver : pas de culture, neige, besoin de bois de chauffe.

## 2. Les Lutins
- Petites créatures **bleu sombre** (validé), environ 1 bloc de haut. Départ : **2 à 10 lutins, réglable avant de lancer la partie** (6 par défaut) + un chariot de vivres, de semences et d'outils (`data/start.json`).
- Fiche : nom, **métier**, niveau d'expérience du métier, besoins.
- **Besoins** : faim, sommeil, chaleur (hiver), moral. Moral bas → travail lent ; très bas → il quitte le village.
- **Déplacement** : marche, monte une marche d'**1 bloc**, ne saute pas plus ; escaliers, échelles et ponts à construire pour le reste.
- **Les lutins naissent** (validé) : voir §2b.

## 2b. Cycle de vie
- **Naissance** : un couple de lutins adultes dans une **maison** avec un lit libre, village nourri et moral correct → chance de naissance (`data/population.json`).
- **Âges** : bébé → **enfant** → adulte → ancien. Un enfant ne travaille pas : il joue, mange et **va à l'école**.
- Ce que l'enfant apprend décide de ce qu'il pourra devenir (§3b).
- **Validé** : les anciens **meurent de vieillesse** (cimetière ; leur expérience peut être transmise en étant maître d'école).

## 3. Métiers
- **Validé** : le métier de base dépend de **l'outil** porté (hache = bûcheron, pioche = mineur…). Les outils se fabriquent → l'économie contrôle la main-d'œuvre.
- Métiers de base : voir `data/jobs.json` — porteur (sans outil), bûcheron, mineur, terrassier, bâtisseur, cueilleur, pêcheur, chasseur, fermier, menuisier, tailleur de pierre, forgeron, cuisinier, **tisserand** (navette), **meunier** (fléau), **boulanger** (pelle à pain).
- Les lutins gagnent de l'**expérience** dans leur métier → travaillent plus vite.
- **Validé — métiers connus** : chaque lutin garde la liste des métiers qu'il a pratiqués, chacun avec **son niveau et sa jauge d'XP**
  (ex. bûcheron niv. 3, mineur niv. 2, fermier niv. 5). Passer à un **métier de base** est libre : métier jamais pratiqué → niveau 1,
  métier déjà connu → il reprend son niveau. La fiche du lutin affiche ces métiers comme les aptitudes.
- **Validé — outil visible seulement en action** : le lutin ne tient son outil que pendant le geste (couper, creuser…) ; au repos, mains vides.
- **Validé** : le chasseur utilise un **fusil à silex** (pas d'arc).

### Panneau d'affectation (gestion automatisée)
- Chaque **bâtiment de travail** (atelier, scierie, ferme, mine, cuisine, école…) a des **postes** (nombre de places).
- **Panneau d'affectation** : liste des bâtiments × lutins, on **attribue un lutin à un bâtiment** d'un tap (ou glisser-déposer).
- Un lutin affecté : récupère **automatiquement** l'outil adapté en réserve, travaille dans ce bâtiment en priorité, y retourne chaque jour.
- Mode « auto » par bâtiment : le jeu remplit les postes vides avec les lutins libres les plus compétents.
- Les lutins non affectés font les tâches générales (porter, récolter les zones désignées, bâtir).
- Alertes : « Scierie : 1 poste vide », « Pas de hache en réserve pour le bûcheron affecté ».

## 3b. Éducation, formation et recherche
- **École** (bâtiment, avec un **maître** affecté) : les enfants y vont le jour ; ils accumulent des **aptitudes** (savoir, force, adresse) selon les cours choisis.
- À l'âge adulte, les aptitudes ouvrent l'accès aux **centres de formation** :
  | Centre | Forme des | Rôle |
  |---|---|---|
  | **Bibliothèque / académie** | **Chercheurs** | produisent des points de recherche → débloquent les **technologies** |
  | **Atelier de maître** | Artisans experts | recettes avancées, meilleure qualité |
  | **Caserne** *(Phase 2)* | **Soldats** (guerrier, archer) | défense, guerre |
  | **Herboristerie** | **Guérisseurs** | soignent les blessés avec des **potions** faites de **plantes médicinales** récoltées (+ eau) |
- Les métiers spécialisés ne s'obtiennent **que par l'éducation** (pas par un simple outil).
- Un adulte non formé peut suivre une formation courte (moins efficace qu'un enfant éduqué).

### Technologies (Phase 1 : arbre court)
- Les chercheurs accumulent des points ; le joueur choisit la prochaine technologie (`data/technologies.json`).
- Exemples : charrue (rendement agricole), moulin (farine plus rapide), maçonnerie (pierre taillée, tours), fours à briques, fer forgé (outils durables), écriture (école améliorée).
- Phase 2 : technologies militaires.
- **Validé : pas de mages ni de magie** (ton murim réaliste). Le soin passe par le **guérisseur**.

## 4. Récolte (même logique que Castle Story)
- Menu **Récolter** (à côté de Construire) : **couper** des arbres, **creuser** (trou, **mine**, **puits**), **cueillir**, **chasser**, **pêcher**.
- **Validé — zone en cercle** : un tap pose un cercle dont le **rayon se règle de 1 à 20 cases** ; **toutes** les ressources
  du bon type à l'intérieur sont sélectionnées (arbres, buissons, lin sauvage, gibier…). Creuser : sélection en 3D (bloc, cube, puits).
- **Validé — tâches assignables** : chaque ordre de récolte ou de chasse apparaît dans le **tableau des tâches** ; on peut y
  **assigner des lutins précis** (sinon les lutins du bon métier la prennent d'eux-mêmes).
- Désigner = des ordres sur un **tableau de tâches** ; les lutins du bon métier les prennent d'eux-mêmes.
- Pêche : poste de pêche au bord de l'eau. Chasse : zone de chasse (fusil à silex) → viande et peaux.
- Creuser : sélection en 3D, **bloc par bloc** ou par cube de 4 ; les couches inférieures se découvrent en creusant.
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

### Routes
- **Validé** : **route en terre** (terre tassée, ×1,3 de vitesse) et **route pavée** (pierre, ×1,6), posées **à plat sur le sol**
  case par case (glisser = tracé), comme un champ. Les lutins préfèrent les routes dans leurs trajets (`data/blocks.json` › speed_mult).

### Constructions de départ
- Dès le début : **tente** (3 peaux + 2 bûches, **1 lutin par tente**), feu de camp, zone de réserve, établi de menuisier (`data/buildings.json`).
- Ensuite : puits (creusé jusqu'à la nappe), moulin, four à pain, rouet, métier à tisser, puis maisons en blocs.

### Objets et pièces
- **Objets** placés sur les blocs : lit, foyer, table, coffre, étagère, établis, porte, fenêtre, torche, échelle.
- Un volume **fermé** (murs + toit) = une **pièce**, typée selon ses objets (`data/rooms.json`) : maison, dortoir, atelier, cuisine, réserve.
- Une pièce chauffée et meublée donne du moral et protège du froid.

## 6. Agriculture
- **Validé : champs posés case par case**, comme une construction (case de champ sur terre ou herbe) : forme libre.
- On choisit la **culture par case** : **blé**, **orge**, **lin**, **pomme de terre** (`data/crops.json`).
- Rendements **réalistes** (≈ 1 grain semé pour 3 récoltés ; pomme de terre 1 → 5) ; × fertilité, niveau du fermier ; rien ne pousse l'hiver.
- Les **tiges** des céréales donnent la **paille** (chaume des toits, litières).
- Lin sauvage à cueillir au début, puis cultivé. **[Plus tard]** élevage : moutons (laine), poules (œufs).

## 7. Production (chaînes)
- Sur des **établis** avec liste de commandes (« faire 20 planches », « garder 50 pains en stock »).
- Bûche → planches ou poutres ; pierre → pierre taillée ; argile → briques ;
  **blé/orge → moulin (farine) → four (pain, avec eau du puits)** ; minerai + charbon → lingot → outils ;
  **lin → rouet (fil) → métier à tisser (tissu) → vêtements** ; peaux → tentes ou cuir ; poisson/viande → repas.
- Bonus si l'établi est dans une pièce du bon type (atelier, cuisine).

## 8. Gestion et objectifs (partie longue)
- **Validé — cloche d'alerte** (bouton court sur la fiche et la barre du haut) : choisir **Mobiliser** (prendre les armes, point de rassemblement)
  ou **Se cacher** (courir à l'abri). **Validé : dès le Bac à sable** (loups, ours), puis contre les orcs en Phase 2.
- Ressources affichées en haut : **Nourriture** (= total de tous les aliments, détail dans un menu déroulant), bois, pierre, fer, **or** (échanges).
- Tableau de bord : stocks, production/consommation par jour, lutins, moral, alertes (famine, froid, plus d'outils).
- **Rangs** : Campement → Hameau → Village → Bourg. Chaque rang débloque matériaux, objets, métiers.
- Objectifs facultatifs proposés au fil de la partie (« construire une tour de 20 blocs », « nourrir 30 lutins un hiver »).

# PHASE 2 — MODE AVENTURE ROYALE (à détailler après la Phase 1)
- Départ avec **3 à 4 lutins**, un roi/une reine lutin à protéger.
- **Orcs** rouges grassouillets : camps sur la carte, raids nocturnes, sièges avec béliers et échelles.
- **Fiche de guerrier** : techniques de combat (niveaux), ennemis vaincus, **réputation** avec titres, et **grades** :
  Recrue → Soldat → Capitaine → Commandant → Général. Ton inspiré du **murim** (maîtres, techniques, légendes) **sans magie abusive**.
- **Équipement des soldats** (`data/equipment.json`) : **arme** (lance, épée courte, **fusil à silex** + balles et poudre),
  **armure** (tissu matelassé, **cuir**, **fer** : plus de défense, moins de vitesse), **uniforme** aux couleurs du village (+moral).
  Ateliers liés : **armurerie** (lances, épées, armures de fer), **atelier d'arquebusier** (fusils, munitions),
  **tannerie-sellerie** (cuir, armures de cuir, métier **tanneur**), **atelier de couture** (gambisons, uniformes, vêtements).
- Combat : **soldats** (lanciers, fusiliers…) formés à la caserne (§3b), ordres de groupe, défense par étages, créneaux.
- **Destruction et effondrement** des blocs non soutenus (sièges spectaculaires).
- **Carte régionale** : autres royaumes lutins (IA), tribus orques, provinces à prendre.
- **Diplomatie** : émissaires, alliances, tributs, commerce, déclarations de guerre.
- But de partie : unifier la région / devenir Haut-Roi. **[À VALIDER]**

## Questions ouvertes
1. Carte aléatoire, ou aussi des cartes dessinées à la main ? (par défaut : aléatoire seedée)
