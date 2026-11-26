# Prompt 1 — Planches de style (à lancer en premier)

Copie tout le bloc ci-dessous dans Claude Code ouvert sur le dépôt World-of-Lutin-Game.

```
Lis CLAUDE.md et tout docs/ (surtout 02-conception et 06-direction-artistique).
On ne code PAS encore le jeu. Ta mission : me proposer le style visuel en images pour que je le valide sur mon téléphone.

1. Installe ce qu'il faut dans le cloud (Blender en ligne de commande, Python, Pillow) — skill assets-gratuits-cloud adaptée à ce projet.
2. Crée dans docs/style/ des images PNG (1600 px de large, lisibles sur téléphone) :
   a. lutin-variantes.png : 3 propositions de design du Lutin de base (bleu, petit, rond, grosse tête), modélisées en low-poly dans Blender et rendues de face, 3/4 et dos. Numérote-les A, B, C.
   b. fiches-metiers.png : pour la variante que tu recommandes, une fiche par métier (porteur, bûcheron, mineur, terrassier, bâtisseur, cueilleur, pêcheur, chasseur, fermier, menuisier, tailleur de pierre, forgeron, cuisinier, maître d'école, chercheur, artisan expert) : tenue, couleur de bonnet, outil visible. Nom du métier sous chaque lutin.
   c. ages.png : bébé, enfant, adulte, ancien.
   d. fiche-personnage.png : maquette de la fiche d'un lutin dans le jeu (nom, âge, métier, aptitudes, besoins, bâtiment affecté).
   e. blocs.png : tous les blocs de data/blocks.json texturés (atlas), plus 2 variantes de palette (A : chaleureuse, B : plus réaliste).
   f. scene-village.png : une petite scène de démonstration (rivière, arbres, une maison en blocs, quelques lutins au travail) vue avec la caméra du jeu, de jour et en hiver.
   g. interface.png : maquette de l'écran principal en paysage (barre du haut, barre d'outils du bas, panneau d'affectation ouvert).
   h. orcs-apercu.png (bonus, pour plus tard) : 2 propositions d'Orc rouge grassouillet, à côté d'un lutin pour l'échelle.
3. Rassemble tout dans docs/style/PLANCHES.md (une image par section, 2 lignes d'explication chacune, et la question précise que je dois trancher).
4. Tout doit être original : aucune ressemblance avec des personnages existants. Assets gratuits uniquement, crédités dans assets/CREDITS.md.
5. Commit, pousse sur main, puis donne-moi la liste courte de mes choix à faire (ex. « Lutin : A, B ou C ? Palette : A ou B ? »).
```

## Ensuite
Réponds-lui tes choix (ex. « Lutin B mais tête plus grosse, palette A, interface OK »). Il itère jusqu'à ce que tu dises **« style validé »**.
À ce moment, demande-lui :
```
Style validé. Écris docs/style/STYLE-VALIDE.md avec toutes les décisions (modèles retenus, palette, proportions, règles de texture, interface) et les images finales. Commit et pousse.
```
Puis lance le prompt 2.
