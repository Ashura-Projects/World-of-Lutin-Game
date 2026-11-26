---
description: Vérifie sérieusement le travail avant de le déclarer fini
---
Vérifie dans cet ordre, sans rien sauter :

1. Import headless du projet (`godot --headless --import`) : aucune erreur, aucun nouveau warning.
2. Tous les tests GUT en headless : tous verts, donne le nombre.
3. `gdformat --check` et `gdlint` sur `src/` et `tests/`.
4. Test sauvegarde → chargement (monde de blocs + état sim identiques).
5. Démontre le critère de réussite du jalon en cours (docs/03) : test, capture headless ou mesure chiffrée.
6. Si le rendu a changé : capture, et regarde-la vraiment (faces manquantes, trous entre chunks, textures).
7. Mesures perf si le monde ou les lutins ont changé : temps de maillage d'un chunk, temps du tick.
8. Travail important : fais relire le diff par un agent indépendant face à CLAUDE.md et docs/02.

Rapport court et honnête :
- ✅ validé (avec la preuve)
- ⚠️ pas testé (ex. « pas testé sur le téléphone »)
- ❌ ne marche pas encore
$ARGUMENTS
