# Prompt 0 — Passation complète à Claude Code

Tu reprends le projet **World of Lutin** d'Ashura. Ce fichier résume tout ce qui a été décidé avant toi et te dit dans quel ordre agir.

## 1. Le projet en bref
- Jeu Android (paysage, Xiaomi 14T Pro) de construction en blocs, gestion et stratégie médiéval-fantastique : l'esprit de Castle Story, **amélioré** (économie, métiers, agriculture, saisons, éducation, puis royaume et guerre).
- Projet personnel, non commercial, **zéro dépense**. Ashura pilote depuis son téléphone et ne tape aucune commande.
- Sources de vérité : `CLAUDE.md` (règles), `docs/02-conception.md` (mécaniques), `docs/03-feuille-de-route.md` (jalons), `data/*.json` (équilibrage). Lis-les en entier avant d'agir.

## 2. Décisions déjà prises par Ashura (ne pas remettre en question)
- Créatures : **Lutins** bleus (petits, ronds, design original). Ennemis (Phase 2) : **Orcs** rouges grassouillets.
- Terre ferme : plaines, forêt, rivière, lac, montagne. Récolte « à la Castle Story » + pêche, chasse, cueillette, **agriculture** et saisons.
- Construction : **tap sur la face d'un bloc** = bloc-plan collé à cette face (comme Minecraft) ; les lutins apportent les matériaux et bâtissent.
- **Métier de base = outil porté** (hache = bûcheron…). **Panneau d'affectation** lutin → bâtiment (outil pris automatiquement, mode auto).
- Les lutins **naissent**, grandissent (bébé, enfant, adulte, ancien) et **meurent de vieillesse**.
- **École** pour les enfants (aptitudes : savoir, force, adresse, magie) puis **centres de formation** à l'âge adulte : chercheur (débloque les **technologies**), artisan expert ; en Phase 2 soldat et **mage**.
- Mages : 4 voies **choisies à l'âge adulte** — soin, protection, météo, combat (Phase 2).
- Phase 1 = **Bac à sable sans ennemis** (J0 → J8). Phase 2 = **Aventure Royale** (orcs, sièges, royaumes, diplomatie, conquête).
- Carte : génération aléatoire seedée (par défaut ; cartes dessinées à la main peut-être plus tard).
- Technique : Godot 4.7.x stable, GDScript typé, moteur de blocs maison (ADR-001), tests GUT, APK par GitHub Actions, assets gratuits (Blender CLI + banques CC0).

## 3. Étape 0 — Vérifier ton environnement (obligatoire, avant tout)
Teste et rapporte en 3 lignes :
1. **Écriture sur le dépôt** : crée une branche `test/acces`, pousse-la, supprime-la.
2. **Réseau** : `pip download` d'un petit paquet ; accès à `download.blender.org` et `github.com/godotengine/godot/releases`.
3. **Outils** : Python, Pillow.

Ensuite :
- **Pas d'écriture sur le dépôt** → STOP. Dis à Ashura : « Installe l'appli Claude de GitHub sur l'organisation Ashura-Projects avec accès au dépôt World-of-Lutin-Game, puis relance une nouvelle session. »
- **Écriture OK mais réseau coupé** → n'invente pas de moteur de rendu maison. Fais tourner Blender et Godot **sur GitHub Actions** (les serveurs GitHub ont le réseau) :
  - un workflow `.github/workflows/style-renders.yml` (déclenché par push sur `style/**` + `workflow_dispatch`) qui installe Blender (archive officielle), lance `tools/style/*.py` en `blender -b -P`, et **commit les PNG** dans `docs/style/` sur la branche ;
  - tu récupères les images par `git pull`, tu les regardes vraiment, tu corriges les scripts, tu relances ;
  - dis aussi à Ashura qu'il peut passer l'accès réseau de l'environnement Claude Code sur « Complet » pour les prochaines sessions.
- **Tout OK** → travaille en local normalement.

## 4. Étape 1 — Planches de style
Exécute `prompts/01-planches-de-style.md`. Rendus **Blender** obligatoires pour tout ce qui est en 3D (lutins, métiers, âges, blocs, scène, orcs) ; Pillow accepté pour les maquettes 2D (fiche personnage, interface).
Envoie les images à Ashura dans la conversation, puis attends ses choix. Itère jusqu'à « style validé », puis écris `docs/style/STYLE-VALIDE.md`.

## 5. Étape 2 — Le Bac à sable complet
Seulement après « style validé » **et** sur la demande d'Ashura : exécute `prompts/02-sandbox-complet.md` (mode marathon, J0 → J8).
Si la session s'arrête : `prompts/03-reprise-et-corrections.md`.

## 6. Rappels
- Réponses à Ashura : en français, courtes, résultat d'abord, lisibles sur téléphone.
- Jamais d'autre nom que « Ashura ». Rien de Castle Story (noms, personnages, assets).
- Rapport honnête : ce qui est testé, pas testé, cassé.
