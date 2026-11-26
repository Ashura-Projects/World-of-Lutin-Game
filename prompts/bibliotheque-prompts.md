# Bibliothèque de prompts — à copier dans Claude Code

## 0. Démarrage (une seule fois)
```
Lis CLAUDE.md et tout docs/. Lance la skill setup-jeu-cloud en l'adaptant à ce projet
(nom « World of Lutin », Godot 4.7.x, nouveau projet, rien de Dynasty). Puis réalise le jalon J0 de docs/03.
Termine par /verifier et donne-moi le lien de l'APK.
```

## 1. Lancer un jalon
```
/jalon J[numéro]
```

## 2. Ajouter / changer une mécanique
```
Je veux [mécanique en mots simples + un exemple de situation en jeu].
Mets d'abord à jour docs/02-conception.md (montre-moi le passage), puis code + JSON + tests.
Si ça sort du jalon en cours, range-la dans docs/idees.md.
```

## 3. Bug vu sur le téléphone
```
Bug sur l'APK [commit] : [ce que je faisais] → [ce qui s'est passé] au lieu de [ce que j'attendais].
Reproduis-le avec un test GUT qui échoue, corrige, puis /verifier.
```

## 4. Lag
```
Ça rame quand [situation]. Mesure d'abord (FPS, temps du tick, temps de maillage des chunks, draw calls),
donne les chiffres, corrige la cause principale, re-mesure. Méthode de la skill dynasty-optimisation-android.
```

## 5. Construction au doigt pas agréable
```
La pose de blocs est pénible quand [situation]. Propose 2 améliorations de contrôle, applique la meilleure,
et ajoute un test du lancer de rayon / de la face visée si c'est un bug de précision.
```

## 6. Équilibrage
```
[Problème : famine au 2e hiver, pierre trop rare…]. Propose 2–3 réglages dans data/*.json,
applique le meilleur et prouve-le par une simulation accélérée headless (ex. 3 ans de jeu).
```

## 7. Assets
```
Il me faut [modèle de lutin bûcheron / textures de briques / sons de pioche]. Respecte docs/06,
assets gratuits ou faits dans Blender, optimisés mobile, CREDITS.md à jour, capture avant/après.
```

## 8. Point d'étape
```
/point
```
