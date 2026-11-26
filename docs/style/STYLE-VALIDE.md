# STYLE VALIDÉ — World of Lutins

Validé par Ashura le 2026-11-26. **Référence figée** pour tous les assets du jeu (CLAUDE.md §5). Planches : `docs/style/`.
Scripts de référence (modèles, couleurs, poses) : `tools/style/` — le jeu réutilise les mêmes formes et couleurs.

## 1. Ambiance générale
- **Médiéval réaliste, un peu sombre**, avec une **vraie journée** lumineuse (soleil voilé), un crépuscule chaud (torches) et des hivers froids.
- Ton « **murim** » : maîtres, techniques de combat, réputation et légendes — **pas de magie**, pas d'effets lumineux surnaturels.
- Brume légère sur les lointains (passe de brouillard), contraste moyen-fort (rendu type AgX « Medium High Contrast »).
- Monde : grande plaine, rivière et lac, forêts, collines à minerais, **montagne à explorer**. Carte vierge au départ.

## 2. Les Lutins (variante A « Bouille »)
- Petits (≈ 1 bloc), **grosse tête ronde**, nez rond, grands yeux noirs avec reflet, joues roses, **oreilles en pointe**, corps en poire, bottes.
- **Peau bleu sombre** : `#46 6C A0` (70, 108, 160), nez/ombre `#36 56 84` (54, 86, 132). Anciens : peau plus pâle, barbe blanche, canne.
- Tenues : couleurs **désaturées et assombries** (fonction `grade()` de `tools/style/lutin.py` : 60 % couleur + 40 % gris, × 0,72).
- Le **métier se lit au bonnet et à la tenue** (table `OUTFITS` de `lutin.py`).
- **L'outil n'apparaît que pendant l'action** ; au repos, mains vides. Outils légèrement exagérés (× 1,3) pour la lisibilité.
- Âges : bébé (× 0,5, tête × 1,22), enfant (× 0,72, tête × 1,1, cartable), adulte, ancien (× 0,95, dos voûté).

## 3. Uniforme de mobilisation (cloche « Mobiliser »)
- Tunique **bleue du village** (40, 74, 170 avant `grade()`), **chapel de fer** (calotte + large bord), **baudriers blancs croisés** avec plaque de laiton, giberne.
- Armes : **fusil à silex** (porté en bandoulière ; épaulé canon vers l'avant pour viser ; au tir : flash + fumée + éclair de lumière) ou **lance** (en garde, pointe vers l'avant).
- Planche : `uniforme-soldat.png`, `fusil-tir.png`.

## 4. Faune et ennemis
- **Loup** : gris, low-poly, yeux jaunes, ≈ 0,8 bloc au garrot (`tools/style/render_tir.py`). Ours : même style, massif, brun sombre.
- **Orc B « Bedaine à crête »** (Phase 2) : rouge, ventre clair, museau, crête noire, épaulière de récupération, couperet (`render_orcs.py`).

## 5. Blocs
- **Palette B** (réaliste, pas trop sombre) — `tools/style/atlas.py`, une **seule texture-atlas**, tuiles **32×32 px**, filtrage « au plus proche ».
- Légère variation de bruit par pixel, pas de damier. Dessus/côté distincts pour herbe, neige, bûches, chaume.
- Blocs-plans : **bleu translucide** (alpha 0,45, filaire) ; à démolir : rouge.

## 6. Végétation et objets
- Arbres low-poly à facettes : pins (3 cônes), feuillus (icosphères), bouleaux ; un seul bois récolté : la **bûche**.
- Couleurs de végétation désaturées (`voxel.g_()`), arbres nus et neige l'hiver.

## 7. Interface
- **Fer sombre** (`#22 1E 1E`), **filets dorés** (`#C4 9E 54`), **boutons rouge sang et or** (`#8C 24 20`), **parchemin vieilli** (`#DE CE AC`).
- Titres en **Cinzel** (OFL, `assets/fonts/`), textes en DejaVu Sans. Zones tactiles ≥ 48 dp.
- Écran : barre du haut (temps, vitesse, population, ressources déroulantes, cloche, engrenage), 7 menus en bas
  (Construire, Récolter, Zones, Lutins, Militaire, Commerce, Gestion), curseur d'étage à droite.
- Boîtes de dialogue : portrait rond doré, texte sur parchemin, 2-3 choix. Menu engrenage, menu principal (`menu-principal.png`).
- Référence : `interface.png`, `menu-engrenage.png`, `menu-principal.png`, `fiche-personnage.png`, `fiche-guerrier.png`.

## 8. Lumière (rendu Godot)
- Jour : soleil chaud voilé (~ 48° d'élévation), ciel gris-bleu clair, brouillard de profondeur léger.
- Crépuscule : soleil bas orangé, torches et fenêtres chaudes (lumières ponctuelles).
- Hiver : lumière froide, neige sur les dessus de blocs, rivière gelée.
