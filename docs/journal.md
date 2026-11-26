# Journal du marathon (Bac à sable J0 → J8)

Reprise : lire ce fichier, puis `prompts/03-reprise-et-corrections.md`.

| Jalon | État | Preuves |
|---|---|---|
| J0 — Fondations | **fait** | 10 tests verts ; build GitHub Actions vert (tests + APK) ; `docs/captures/titre.jpg` |
| J1 — Le monde en blocs | **fait** (perf téléphone non mesurée) | même graine = même monde (test) ; 256×256 : génération 2,4 s, maillage 2,4 s, pire chunk 5,2 ms, 376 k triangles (CPU cloud) ; `monde_128.jpg` |
| J2 — Construire au doigt | **fait** | rayon DDA + face, ligne/remplir/mur/gomme, annuler/rétablir, curseur d'étage ; test « tour creuse de 10 + escalier » ; `construire.jpg` |
| J3 — Les Lutins | **fait** | A* (marche d'1 bloc max), tour + escalier atteinte (test), 3 jours simulés sans blocage (test), métiers connus (test), sauvegarde colonie ; `lutins.jpg`, `fiche.jpg` |
| J4 — Récolte & métiers | **fait** (panneau bâtiments au J6) | bois et pierre arrivent en réserve sans action (tests couper/creuser/cueillir/chasser/assigner) ; `recolte.jpg`, `travail.jpg` |
| J5 — Les lutins bâtissent | **fait** | maison (murs, toit, porte, 4 lits) bâtie par les lutins, reconnue « maison », ils y dorment (test) ; tentes attribuées ; `village.jpg` |
| J6 — Agriculture & production | **fait** | champ case par case → récolte + paille (test), blé → farine → pain avec l'eau du puits (test), hiver de 5 jours en autonomie (test) ; `ferme.jpg` |
| J7 — Prédateurs, gestion & sauvegarde | **fait** | loups (nuit) et ours, milice qui abat le loup (tests), sauvegarde → réouverture identique (test), rangs/objectifs/bilan (tests) ; `loups.jpg` |
| J8 — Familles, école & recherche | **fait** | enfant né au village → école → chercheur → « Écriture » découverte (test) ; mort de vieillesse (test) ; `recherche.jpg` |

## J0 — Fondations
Plan : projet Godot 4.7.2 (rendu Mobile, paysage 20:9), autoloads (EventBus, DataRegistry, Rng, GameClock, SaveManager,
Settings, GameSetup), GUT 9.7.1 headless, export Android arm64 (`com.ashura.worldoflutin`), workflow GitHub Actions
(tests puis APK, publication `dernier-build` sur main), écran titre au style validé avec configuration de partie (2-10 lutins, graine).

## Choix faits sans Ashura
- Godot **4.7.2** (dernière 4.7.x stable avec image godot-ci identique).
- Nom de paquet Android : `com.ashura.worldoflutin`.
- GUT récupéré via le CDN jsDelivr (les archives GitHub d'autres dépôts sont bloquées dans l'environnement cloud).
- Chariot de départ : 6 peaux (2 tentes), le reste par la chasse.
- Carte par défaut 256×256×64 ; si la perf ne tient pas sur le Xiaomi, 128×128 par défaut (mesure au J1).

## Problèmes connus
- Le travail est poussé sur la branche de session `ccr-a284deb7-1npond` ; la fusion dans `main` (qui publie l'APK) attend l'accord d'Ashura.

## J1 — Le monde en blocs
- Chunks 16³ (1 octet/bloc), `VoxelWorld` (vérité), `WorldGenerator` (FastNoiseLite seedé : plaine, rivière, lac, collines, montagne, couches, poches de minerais),
  `ChunkMesher` (faces visibles, tampon 18³, thread `WorkerThreadPool`), arbres/buissons en `MultiMeshInstance3D`, `CameraController` tactile, `SkyLight`.
- Outils : `tools/capture/capture.gd` (captures réelles sous Xvfb), `tools/bench/bench_world.tscn` (mesures).
- Non testé : 60 img/s sur le Xiaomi (la capture cloud tourne en rendu logiciel, ~8 img/s, non représentatif).

## J2 — Construire au doigt
- `VoxelRaycast` (DDA), `Shapes` (ligne, rectangle, mur, boîte de creusage), `EditHistory` (annuler/rétablir), `BuildTool` (1 doigt = construire,
  2 doigts = caméra, aperçu bleu / rouge pour la gomme), `BuildPanel`, curseur d'étage.
- Mode créatif : pose instantanée. Au J5, `BuildTool.place_handler` transformera les poses en plans pour les bâtisseurs.

## J3 — Les Lutins
- `Pathfinder` (A* + tas binaire, routes moins chères), `Lutin` (besoins, métiers connus niveau + XP, chemin), `Colony` (apparition autour du chariot
  avec le contenu de `start.json`, besoins, manger à la réserve, dormir la nuit, flâner ; budget de chemins par tick), `Stockpile`.
- Vue : `LutinModel` (modèle validé reconstruit en primitives, tenues de `data/outfits.json`), `LutinsView` (lissage, animation, sélection au doigt),
  `LutinSheet` (fiche), chariot de départ.

## J4 — Récolte & métiers
- `Flora`, `Fauna` (cerfs, sangliers), `GroundItems`, `TaskBoard` + `TaskExec` : couper, creuser (boîte + / −), puits, cueillir (cercle 1-20),
  chasser (fusil : portée, recharge, dégâts de `equipment.json`), pêcher (tâche répétée), transport automatique par les porteurs (et lutins libres).
- Métiers = outils de la réserve (`Colony.change_job`), mode auto au départ, métiers connus avec XP et vitesse par niveau.
- Interface : menu Récolter (aperçu cercle/boîte, Valider, Assigner…), panneau Lutins (métier, Auto), ressources en haut (Nourriture déroulante),
  routes terre/pavée dans Construire, outil visible seulement en action.
- Reste à faire plus tard : panneau d'affectation lutin → **bâtiment** (au J6, quand les ateliers existent).

## J5 — Les lutins bâtissent
- Écran de configuration (titre → Nouvelle partie) : 2 à 10 lutins, graine.
- `Structures` (tente, feu de camp, établi, lit, foyer, table, étagère, porte, torche), `RoomDetector` (air fermé, porte = fermeture, type selon `rooms.json`).
- `BuildExec` : plan → le bâtisseur prend les matériaux à la réserve → pose ; règle de solidité ; portée de 3 blocs en hauteur (`build_reach_up`).
- En partie, l'outil Construire crée des **plans** (bleus) ; la gomme annule un plan ou ordonne une démolition (rouge). Lits/tentes attribués automatiquement.
- Problème connu : un plan peut être posé à travers un arbre (le tronc reste visible).

## J6 — Agriculture & production
- `Fields` (cases planifiées → labourées → semées en saison → mûres → récoltées ; rendements × fertilité × niveau ; rien ne pousse l'hiver),
  `Production` (commandes « garder N » / « faire N » par atelier, une à la fois ; postes de travail et mode auto ; bois de chauffage l'hiver).
- Tâches « labourer, semer, récolter, fabriquer » : le lutin va chercher les intrants à la réserve (`BuildExec`).
- Menus : Zones (champs par case ou rectangle, culture par case), Gestion (ateliers, affectation lutin → bâtiment, commandes).
- Froid : l'hiver, la chaleur baisse loin d'un feu (rayon `heated_radius`) ; feu sans bûches = alerte.

## J7 — Prédateurs, gestion & sauvegarde
- `Combat` : loups (chassent la nuit, en meute), ours ; PV/dégâts/portée/cadence fixes (`animals.json`, `equipment.json`) ; les lutins ont des PV et se défendent ;
  cloche Mobiliser (arme prise en réserve : fusil, sinon lance ; uniforme bleu affiché) / Se cacher / Fin ; XP de combat et tableau de chasse ; potions ; mort.
- `Village` : rangs (`ranks.json`), objectifs (`objectives.json`), bilan quotidien, alertes (famine, froid, bois). `GameSim` regroupe toute la simulation.
- Sauvegarde : auto toutes les 5 min (`autosave_s`), à la mise en arrière-plan et à la fermeture ; test d'aller-retour complet strictement identique.
- Interface : Militaire (cloche, armes, combattants), Tableau de bord (dans Gestion), alertes en bulles, rang dans la barre du haut.
- Non fait : le guérisseur ne va pas encore soigner activement (les blessés boivent une potion à la réserve) ; formation du guérisseur au J8.

## J8 — Familles, école & recherche
- `Population` : vieillissement quotidien, naissances (couple dans une maison fermée avec un lit libre, ≥ 5 jours de nourriture, moral ≥ 50), mort de vieillesse.
- `Education` : école (maître affecté, cours au choix ou équilibré), formations (bibliothèque → chercheur, atelier de maître → artisan expert,
  herboristerie → guérisseur ; formation courte d'adulte à 50 % d'efficacité), production de recherche.
- `Research` : points, choix, effets (rendement, école, farine, vitesse de recherche) et déblocages (blocs et bâtiments grisés tant que non découverts).
- Les enfants ne travaillent pas : école le jour, jeux près de la maison ; les métiers spécialisés exigent une formation.
- Interface : Gestion → Recherche (technologies, cours de l'école, inscriptions).

## v1.0.0 (après J8, demandes d'Ashura)
- Fabrication : 70 recettes, nouveaux ateliers (verrerie, ébéniste, couture, teinture), métiers verrier et ébéniste ; test de cohérence :
  chaque ingrédient s'obtient, chaque atelier/métier existe, chaque outil se fabrique.
- Nature : champignons, roseaux (berges), choux, minerai d'or ; buissons avec baies visibles / cueillis.
- Son : `tools/audio/generate_audio.py` (synthèse originale) → 3 musiques, 5 ambiances, 13 bruitages ; `Audio` (autoload) + `SoundDirector`.
- Faction : éditeur (titre → Nouvelle partie, et Gestion → Faction), emblème dessiné (`Emblem`), fanions 3D, uniforme aux couleurs.
- Meubles et décorations en 3D, moral selon la décoration ; poser un plan sur un arbre ordonne de le couper.
- Commerce (marchand + dialogue), guérisseur actif, Paramètres (volumes, qualité), Crédits, version 1.0.0.
- Performance : recherches de chemin étalées sur plusieurs ticks ; tick moyen 3,5 ms (50 lutins, grande carte, CPU du cloud).

## v1.0.1 (retours d'Ashura sur téléphone)
- Fait : boutons caméra, jauge d'étage déroulante (+ / − / numéro de couche), menu Construire par catégories avec bulle,
  annulation des plans / ordres de récolte / démontage, cercles lumineux sur les cibles, zones de réserve.
- Preuves : 92 tests GUT verts (nouveau `tests/test_orders.gd`), gdlint propre, captures `build/captures/v101_*.png`.
- Choix faits sans Ashura : la réserve reste un stock global ; une zone de réserve est un **point de dépôt/retrait**
  supplémentaire (le plus proche est utilisé), pas un inventaire séparé. Démonter un objet rend tout son coût.
- Non testé : sur téléphone (à faire par Ashura).

## v1.1.0 (retours d'Ashura sur la 1.0.1)
- Fait : ordres directs aux lutins, menu Lutins (liste, familles, métiers), menu Royaume (faction, seigneur, membres,
  prison, diplomatie, lois et impôts), garnison, soldats et entraînement, unités en formation, réserves filtrées,
  charrette déplaçable, menu Ressources, croix sur toutes les fenêtres, joystick, playlist de 7 musiques CC BY,
  logo, fond d'accueil, écran de chargement.
- Preuves : 104 tests GUT verts (nouveaux `tests/test_realm.gd`, filtres de réserve, playlist), gdlint propre,
  tick 3,4 ms (50 lutins), captures `build/captures/v11_*.png`.
- Bogue ancien corrigé : XP de combat, parents, faction, recherche et commerce n'étaient pas sauvegardés.
- Choix faits sans Ashura :
  - « Construire » en mode ordres pose le matériau choisi dans le menu Construire ;
  - la guerre et la paix ne changent que le statut (les raids arrivent avec l'Aventure Royale) ; l'accord commercial
    améliore les prix du marchand ;
  - un soldat est un métier sans tâche civile ; 2 places sans garnison, puis 1 par lit de garnison ;
  - le stock reste commun, les réserves décident seulement où déposer et prendre chaque ressource ;
  - le nom affiché sur le logo et le fond est « World of Lutins » ; le nom de l'appli reste « World of Lutin »
    (à confirmer par Ashura).
- Non testé : sur téléphone.

## Problèmes connus (v1.0.0)
- **Pas testé sur le téléphone** : ni les 60 img/s, ni le tactile réel, ni le son (le cloud n'a pas de carte son).
- Le tick reste au-dessus de 4 ms au pire (~10 ms) ; sur téléphone il peut être 1,5 à 2 fois plus lent.
- Les lutins attendent parfois une seconde avant de partir (recherche de chemin étalée).
- La relecture du code par un agent indépendant n'a pas été faite (interrompue).
