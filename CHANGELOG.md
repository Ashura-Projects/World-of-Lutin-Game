# Journal des versions

## 1.2.1 — Silence dans les menus (2026-11-27)
- Plus aucun son dans les menus et l'interface, sans exception : ni clic sur les boutons, ni petite musique
  sur les alertes (demande d'Ashura). La musique et les bruits du monde (hache, loups, tirs…) restent.

## 1.2.0 — Aventure Royale et royaume (2026-11-27)
Phase 2 et Phase 3, demandées par Ashura.
- **Nouvelle partie** : Bac à sable ou **Aventure Royale** ; carte petite, moyenne (×2), grande (×5), gigantesque (×15) ;
  difficulté (facile à légendaire) ; 0 à 3 villages voisins ; orcs ; raids tous les 50 à 200 jours.
- **Orcs** : camps dans les forêts, raids réguliers annoncés par les tambours, ils cassent les murs, les blocs sans appui
  s'effondrent ; on peut attaquer et détruire leurs camps (butin).
- **Défense** : créneaux et remparts, tir depuis les hauteurs, soldats de garnison équipés qui tirent depuis leur poste,
  armures, caserne, tour de guet.
- **Voisins** : villages de lutins jaunes, rouges et vert clair gérés par l'IA (commerce, alliance, guerre, paix, raids,
  conquête de leur village), victoire de l'Aventure Royale.
- **Territoires**, bornes de revendication, **brouillard de guerre**, rencontre des factions, **éclaireurs** (exploration
  autonome, camp la nuit, retour à la base, unité d'éclaireurs).
- **Carte** et minicarte : filtres (territoires, villages, camps, ressources, marqueurs, lutins), marqueurs personnels.
- **Religion** : chapelle, église, autel, cloche ; prêtres, offices, **mariages** et naissances des couples mariés ;
  cardinaux et chef de culte ; religion personnalisée (dogmes) ; prédication chez les voisins et recrutement des convertis.
- **Nourritures** : tarte aux baies, soupe de légumes et aux champignons, pain d'orge, poisson fumé, rôti, galette, compote.
- **Technologies** : fortifications, exercices militaires, théologie, cartographie.
- **Paramètres** en onglets (Son, Musique, Graphismes, Jeu) avec croix ; graphismes détaillés (ombres, distance de vue,
  résolution, anticrénelage, brume, images/s, herbes) ; affichage limité à la distance de vue (grandes cartes fluides).
- **zZz** au-dessus des lutins qui dorment ; tutoriel de départ ; menu **débug** caché (5 touchers dans le coin de l'accueil).

## 1.1.0 — Royaume, ordres et confort (2026-11-27)
Retours d'Ashura sur la 1.0.1.
- **Lutins** : toucher un lutin → barre d'ordres qui reste ouverte (Auto : couper, cueillir, chasser, aller ici ;
  Construire ; Creuser ; Charrette) jusqu'à la croix ✕. Menu Lutins : liste (toucher = choisir, double toucher = centrer
  la caméra), Familles (parents, enfants, frères et sœurs, conjoint), Métiers.
- **Royaume** (nouveau menu) : faction et emblème, seigneur (salle du trône), membres (promouvoir, soldat, cage),
  diplomatie (3 voisins), lois et impôts. Nouveaux meubles : trône, cage en bois, cage en fer. Sol d'entraînement.
- **Militaire** : garnison, soldats en uniforme aux couleurs de la faction qui s'entraînent, **unités** en formation
  (ligne, colonne, carré, coin) avec ordres Aller à / Attaquer / Tenir / Rentrer.
- **Réserves** avec filtre (tout, catégories, objets) ; **charrette** déplaçable par un lutin.
- **Ressources** : menu par catégories (toucher une ressource en haut).
- **Menus** : croix ✕ sur toutes les fenêtres, plus aucun menu sur la barre du bas, joystick de caméra,
  boutons caméra et étage sans bruit de clic.
- **Musique** : 7 morceaux médiévaux et apaisants de Kevin MacLeod (CC BY 4.0, voir Crédits) ; playlist dans
  Paramètres (toutes en boucle, aléatoire, un seul morceau, cocher ses morceaux).
- L'application s'appelle maintenant **World of Lutins**.
- **Logo** de l'application, **fond d'accueil** et **écran de chargement** (barre, phrases drôles, bouton Jouer).
- Corrections : l'XP de combat, les liens de famille, la faction, la recherche et le commerce sont maintenant bien
  sauvegardés ; plus de prénoms en double au départ.

## 1.0.1 — Interface plus claire (2026-11-26)
Retours d'Ashura après le premier essai sur téléphone.
- **Caméra** : boutons pivoter ⟲ ⟳, zoom + −, incliner ⤒ ⤓ (en plus des gestes) ; deux doigts déplacent la vue.
- **Étage** : bouton « ▤ » dans la barre du haut → jauge déroulante avec « + » en haut, « − » en bas, numéro de couche affiché, « Tout voir ».
- **Construire** : catégories en haut (Blocs, Sols et routes, Meubles, Décoration, Ateliers, Bâtiments), choix en dessous ;
  choisir un élément réduit le menu en **bulle** sur le côté (toucher la bulle le rouvre) ; « ✋ Déplacer » pour bouger la caméra menu ouvert ;
  « ↶ Annuler » annule le dernier groupe de plans ; la **Gomme** annule un plan ou démonte un objet (matériaux rendus).
- **Récolter** : mode « ✕ Annuler » (annule les ordres dans le cercle), « ↶ Dernier ordre », menu compact ;
  **cercles lumineux** au sol sous chaque arbre, plante, gibier ou poste de pêche ciblé.
- **Zones** : « Réserve » / « Retirer réserve » — zones de stockage au sol (dalles dorées) ; les lutins déposent, prennent
  les matériaux et mangent à la réserve la plus proche.

## 1.0.0 — Bac à sable complet (2026-11-26)
Première version complète du mode **Bac à sable**.

**Monde** : grande carte vierge 256×256×64 en couches (herbe, terre, pierre, roche profonde, socle ; charbon, fer, or, argile, gravier),
grande plaine, rivière, lac, forêts, collines, montagne ; jour/nuit, 4 saisons, hiver enneigé, brume.
**Lutins** (2 à 10 au départ) : besoins (faim, sommeil, chaleur, moral), PV, métiers par outil avec niveaux et XP mémorisés,
naissances, enfance et école, formations (chercheur, maître d'école, artisan expert, guérisseur), vieillesse.
**Construction** au doigt : bloc, ligne, rectangle, mur, gomme, routes (terre ×1,3 ; pavée ×1,6), curseur d'étage, annuler/rétablir ;
les plans sont bâtis par les lutins (matériaux apportés depuis la réserve). Pièces détectées, moral selon la décoration.
**Récolte** : couper, creuser (largeur/longueur/profondeur réglables), puits, cueillir (baies, lin, champignons, plantes médicinales, roseaux),
chasser au fusil à silex, pêcher ; sélection en cercle de 1 à 20 cases ; tâches assignables à des lutins précis.
**Agriculture** : champs case par case (blé, orge, lin, pomme de terre, chou), rendements réalistes, paille.
**Fabrication** : 70 recettes, 20 ateliers (scierie, tailleur, four à briques, verrerie, fourneau, enclume, moulin, four, rouet,
métier à tisser, couture, teinture, tannerie, ébéniste, herboristerie…) : planches, poutres, verre, fioles, lingots, outils, armes,
meubles (lit, table, chaise, banc, coffre, armoire, étagère, porte, tonneau, caisse, râtelier), décorations (lanterne, tapis, pot de fleurs, fanions).
**Faction** : éditeur (nom, devise, couleurs, écu, partition, symbole) ; fanions muraux et sur poteau ; uniforme aux couleurs.
**Défense** : loups (la nuit) et ours, cloche (Mobiliser avec fusil ou lance / Se cacher), XP de combat, guérisseur et potions.
**Gestion** : affectation lutin → bâtiment, commandes d'atelier, tableau de bord, rangs (Campement → Bourg), objectifs, alertes,
marchand ambulant (acheter / vendre contre de l'or), recherche et technologies.
**Son** : 3 musiques originales, ambiances selon la caméra et le zoom (forêt, eau, nuit, vent, feu), bruitages.
**Sauvegarde** automatique (5 min, mise en arrière-plan) ; menus principal, engrenage, paramètres (volumes, qualité), crédits.
