# 03 — Feuille de route

Règle : **un jalon = un APK jouable** sur le Xiaomi 14T Pro. On passe au suivant quand Ashura a validé les critères sur le téléphone.

## Phase 1 — Mode Bac à sable
| Jalon | Contenu | Critère de réussite |
|---|---|---|
| **J0 — Fondations** | Projet Godot, CI → APK, GUT headless, autoloads (`GameClock`, `EventBus`, `DataRegistry`, `SaveManager`, `Rng`) | APK installable sur écran titre ; tests verts en CI |
| **J1 — Le monde en blocs** | Chunks 16³, maillage + atlas, génération (rivière, forêt, montagne, lac), arbres en MultiMesh, caméra libre tactile | 60 FPS en survolant toute la carte ; même seed = même monde |
| **J2 — Construire au doigt** | Tap sur une face = bloc, glisser = ligne/remplir/mur, gomme, curseur d'étage — en **mode créatif** (pose instantanée, sans lutins) | Construire une tour creuse de 10 blocs avec escalier en < 2 min, sans erreur de pose |
| **J3 — Les Lutins** | 6 lutins, déplacement 3D (marche d'1 bloc, escaliers, échelles), faim/sommeil, jour/nuit, sélection + fiche | Un lutin rejoint le sommet de la tour du J2 par l'escalier ; 3 jours sans blocage |
| **J4 — Récolte & métiers** | Outils = métiers, coupe, minage par zone, cueillette, pêche, chasse, réserve, porteurs | Bois et pierre récoltés arrivent en réserve sans action du joueur |
| **J5 — Les lutins bâtissent** | Plans → apport des matériaux → pose par les bâtisseurs ; objets ; détection des pièces | Une maison (murs, toit, porte, lits) est bâtie par les lutins et ils y dorment |
| **J6 — Agriculture & production** | Champs, saisons, établis + commandes, chaînes MVP, chauffage l'hiver | Le village passe un hiver complet en autonomie |
| **J7 — Gestion & sauvegarde** | Tableau de bord, alertes, arrivée de lutins, rangs, objectifs, sauvegarde auto | 1 h de partie sans bug bloquant ; sauvegarde → réouverture = identique |

## Phase 2 — Aventure Royale
| Jalon | Contenu |
|---|---|
| J8 | Orcs, raids, combat, guerriers/archers |
| J9 | Destruction, effondrement, sièges |
| J10 | Carte régionale, royaumes IA, diplomatie |
| J11 | Guerres, conquête, but de partie |
| J12 | Sons, musique, tutoriel, équilibrage |

## Jalon en cours
**J0 — Fondations**
