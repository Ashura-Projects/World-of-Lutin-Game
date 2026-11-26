# Prompt 2 — Construire tout le mode Bac à sable (J0 → J8)

À lancer **seulement quand `docs/style/STYLE-VALIDE.md` existe**. Copie tout le bloc dans Claude Code.

```
Mode marathon (voir CLAUDE.md §5). Construis TOUT le mode Bac à sable de World of Lutin : jalons J0 à J8 de docs/03-feuille-de-route.md, dans l'ordre, sans t'arrêter pour me demander de valider entre les jalons.

Avant de commencer :
- Lis CLAUDE.md, tout docs/ (y compris docs/style/STYLE-VALIDE.md) et tout data/.
- Lance la skill setup-jeu-cloud adaptée à ce projet (World of Lutin, Godot 4.7.x stable, nouveau projet, rien de Dynasty) : Godot headless, GUT, gdtoolkit, build APK par GitHub Actions.
- Crée docs/journal.md (tableau des jalons + « Choix faits sans Ashura » + « Problèmes connus »).

Pour CHAQUE jalon :
1. Plan court dans docs/journal.md.
2. Code + données JSON + tests GUT, petits commits en français sur une branche jalon-X/sujet.
3. Assets conformes à STYLE-VALIDE.md (Blender en ligne de commande, banques CC0, CREDITS.md à jour).
4. /verifier : import headless sans erreur, tous les tests verts, critère de réussite du jalon démontré (test, capture ou mesure), mesures de perf si le monde ou les lutins ont changé.
5. Si tout est vert : fusion dans main, push, attente du build APK GitHub Actions, mise à jour de docs/journal.md. Sinon : corrige avant de passer au suivant.
6. Point [À VALIDER] non tranché → option la plus simple, notée dans le journal, et tu continues.

Utilise des sous-agents pour paralléliser ce qui est indépendant (ex. modèles 3D pendant le code), et un agent relecteur indépendant à la fin de chaque jalon.
Rien de la Phase 2 (orcs, caserne, armures, sièges, diplomatie). Les loups, les ours et le combat simple sont en Phase 1 (J7).

Si la session doit s'arrêter (limite, contexte plein) : mets docs/journal.md à jour, pousse, et dis-moi où tu t'es arrêté.

À la fin de J8 : rapport court (ce qui marche, ce qui n'est pas testé, problèmes connus), lien du dernier APK, et une liste de 10 choses à tester en priorité sur mon téléphone.
```

## Si ça s'arrête en route
Ouvre une nouvelle session Claude Code sur le dépôt et colle le prompt 3.
