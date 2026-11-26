# CLAUDE.md — Règles du projet « World of Lutin »

Jeu mobile Android de **construction en blocs, gestion et stratégie** médiéval-fantastique.
Base : l'esprit de *Castle Story* (petites créatures à qui on donne des ordres, construction bloc par bloc),
**amélioré** avec une vraie économie (*Settlers*), des métiers et besoins (*RimWorld*), l'agriculture et les saisons (*Manor Lords*),
puis un mode royaume avec guerre et diplomatie (*Europa Universalis*, version légère).

Lis avant toute tâche importante :
- `docs/01-vision.md` — ce qu'on fait / ne fait pas
- `docs/02-conception.md` — toutes les mécaniques (source de vérité du gameplay)
- `docs/03-feuille-de-route.md` — jalon en cours + critères de réussite
- `docs/04-architecture.md` — organisation du code (à respecter)

## 1. Langue et communication
- Tout en **français** : messages, commentaires, docs, commits. Noms de code en anglais (`snake_case`, `PascalCase`).
- Propriétaire : **Ashura**. Aucun autre nom dans fichiers, dépôts, crédits.
- Ashura pilote depuis son **téléphone** et ne tape pas de commandes : réponses courtes, résultat d'abord.

## 2. Pile technique (changement = ADR obligatoire)
- **Godot 4.7.x stable**, **GDScript typé**, rendu **Mobile**. Android 64 bits, paysage, appareil de référence **Xiaomi 14T Pro**.
- Monde en **voxels maison** (pas de module moteur externe) — voir ADR-001.
- Tests **GUT** en headless ; style `gdformat` / `gdlint`.
- Équilibrage dans `data/*.json`. **Aucune valeur de jeu en dur dans le code.**

## 3. Règles d'architecture (détail : docs/04)
1. **Simulation séparée du rendu** : `src/sim/` sans aucun nœud de scène, testable en headless. `src/view/` lit l'état et écoute des signaux.
2. **La grille de blocs 3D est la vérité.** Le maillage n'est qu'une représentation reconstruite.
3. **Tick fixe** 10/s × vitesse (pause, x1, x2, x4), indépendant des FPS.
4. Communication entre systèmes via **`EventBus`**.
5. **Tout est sauvegardable** (`to_dict()` / `from_dict()`), test aller-retour obligatoire.
6. **Déterminisme** : un seul `Rng` seedé par partie.
7. Les deux modes (Bac à sable / Aventure Royale) partagent le même moteur ; le mode n'active que des **règles** et **systèmes** supplémentaires.

## 4. Performance mobile (budgets)
- 60 FPS sur Xiaomi 14T Pro : carte 128×128×48, 50 lutins ; jamais sous 30 FPS.
- Tick sim < 4 ms. Reconstruction d'un chunk modifié < 8 ms, sur un **thread** de travail, jamais dans le thread principal.
- Maillage par chunk 16×16×16, faces cachées supprimées, **une seule texture-atlas** pour tous les blocs.
- Arbres, herbes, objets répétés → `MultiMeshInstance3D`.
- Mesurer avant d'optimiser. Si le maillage GDScript ne tient pas le budget → ADR pour passer ce seul module en GDExtension C++.

## 5. Méthode de travail
1. **Un jalon à la fois.** Rien du mode Aventure Royale (orcs, combat, diplomatie) avant la fin de la Phase 1.
2. Mécanique floue ou contradictoire → **demander à Ashura**, ne pas inventer. Idée hors jalon → `docs/idees.md`.
3. Petits commits ; chaque commit compile, passe les tests et laisse le jeu lançable.
4. Mécanique = code + JSON + tests GUT + doc à jour.

5. **`/verifier` avant de dire « fini »**, rapport honnête (testé / pas testé / cassé). Ne jamais prétendre avoir testé sur téléphone.

### Mode marathon (validé par Ashura)
Quand Ashura lance le prompt « Sandbox complet » (`prompts/02-sandbox-complet.md`) :
- On enchaîne **J0 → J8 sans attendre sa validation entre les jalons** ; elle se fait à la fin, sur téléphone.
- Les jalons restent faits **dans l'ordre**, chacun terminé par `/verifier` (tests verts, critère démontré) avant le suivant.
- Un point [À VALIDER] non tranché → prendre l'option la plus simple, la noter dans `docs/journal.md` (section « Choix faits sans Ashura »), continuer.
- `docs/journal.md` est tenu à jour après chaque jalon : fait, preuves, problèmes, prochaine étape. C'est ce qui permet de **reprendre** dans une nouvelle session.
- Le style visuel est figé par `docs/style/STYLE-VALIDE.md` : ne pas s'en écarter.

## 6. Interdits
- Aucun nom, personnage, logo, texte ou asset de *Castle Story* ni des autres jeux de référence. Nos créatures sont les **Lutins** (bleus) et les **Orcs** (rouges, grassouillets) — designs originaux.
- Rien de payant, pas de service en ligne obligatoire, pas de pub ni de tracking.
- Fichiers > ~400 lignes : découper. Pas de `get_node("../../..")`.
- Pas de réécriture massive sans l'annoncer d'abord.

## 7. Git
- `main` toujours jouable ; branches `jalon-X/sujet`. Commits en français au présent.
- APK construit par GitHub Actions à chaque push sur `main`.
