# Prompt 3 — Reprendre le marathon

```
Mode marathon. Lis CLAUDE.md, docs/journal.md et la feuille de route. Reprends exactement où le journal s'arrête, vérifie d'abord que main compile et que les tests passent, puis continue les jalons du Bac à sable jusqu'à J8 avec la même méthode (prompts/02-sandbox-complet.md).
```

# Prompt 4 — Corrections en masse (après avoir joué)

Note tes retours en vrac pendant que tu joues, puis colle :

```
Voici mes retours après avoir joué à l'APK [commit] :
- [bug ou ressenti 1]
- [bug ou ressenti 2]
- ...

1. Trie-les dans docs/journal.md : bugs bloquants / bugs gênants / confort / équilibrage / idées (les idées vont dans docs/idees.md).
2. Pour chaque bug : test GUT qui le reproduit, correction, test vert.
3. Équilibrage : réglages dans data/*.json, prouvés par une simulation accélérée headless (3 ans de jeu).
4. Confort : applique, capture avant/après.
5. /verifier global, nouvel APK, rapport court : corrigé / pas corrigé et pourquoi.
```
