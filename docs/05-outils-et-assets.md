# 05 — Outils, solutions et assets

Tout **gratuit**, tout **dans le cloud**, piloté depuis le téléphone.

| Besoin | Solution |
|---|---|
| Code | Dépôt **GitHub** `Ashura-Projects/World-of-Lutin-Game` |
| Développement | **Claude Code** (web / appli mobile) |
| Moteur | **Godot 4.7.x stable**, headless dans le cloud |
| Tests | **GUT** + `gdtoolkit` |
| Build Android | **GitHub Actions** → APK téléchargeable depuis l'appli GitHub |
| Modèles (lutins, orcs, objets) | **Blender** en ligne de commande + packs CC0 |
| Textures de blocs | atlas maison 16×16 ou 32×32 px (pixel art propre) généré par script, ou textures CC0 réduites |
| Sons | Kenney Audio, Freesound (CC0), Sonniss GDC + `sox`/`ffmpeg` |

### Skills existantes à réutiliser (écrites pour *Dynasty*, à adapter)
- `setup-jeu-cloud` → configuration du dépôt et du build APK. **À lancer en premier.**
- `assets-gratuits-cloud` → assets via Blender CLI et banques CC0.
- `dynasty-optimisation-android` → mesurer et corriger les lags.
- `dynasty-verification` → vérifier avant de dire « fini ».

### Sources d'assets
| Type | Sources | Licence |
|---|---|---|
| Objets, arbres, props low-poly | Kenney, Quaternius, KayKit | majoritairement CC0 |
| Textures | Poly Haven, ambientCG (à réduire) | CC0 |
| Animations | Mixamo (gratuit, pas CC0 — OK projet perso) ou animations faites dans Blender | |
| Icônes / UI | Kenney UI, game-icons.net | CC0 / CC-BY (créditer) |
| Musique | OpenGameArt, Incompetech | souvent CC-BY (créditer) |

Les **Lutins** et les **Orcs** sont des modèles originaux (simples, low-poly) à créer dans Blender : pas de reprise de modèles existants.
