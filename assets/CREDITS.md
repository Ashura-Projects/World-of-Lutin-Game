# Crédits des assets

## Planches de style (docs/style/)
Aucun asset externe : tout est **fabriqué par script** pour ce projet.
- Lutins, orcs, arbres, outils : modèles low-poly originaux construits à partir de primitives dans **Blender 4.5 LTS** (GPL, outil — les rendus ne sont pas soumis à la GPL). Scripts : `tools/style/`.
- Textures des blocs : pixel art 32×32 généré par `tools/style/atlas.py` (Pillow).
- Police des maquettes : **DejaVu Sans / DejaVu Serif** — licence libre Bitstream Vera / domaine public (https://dejavu-fonts.github.io/).
- Police des titres : **Cinzel** (The Cinzel Project Authors) — SIL Open Font License 1.1, fichiers `assets/fonts/` (licence : `assets/fonts/OFL-Cinzel.txt`), obtenue via le paquet npm @fontsource/cinzel.

## Jeu
- `assets/ui/icon.png`, `assets/ui/icon_adaptive_bg.png` (logo) et `assets/ui/title_bg.jpg` (fond du menu d'accueil et de l'écran de chargement) : images fournies par Ashura.
- Outil de tests **GUT 9.7.1** (`addons/gut/`, licence MIT, non inclus dans l'APK).
- **Ambiances et bruitages** (`assets/audio/ambience`, `assets/audio/sfx`) : générés par synthèse pour ce projet (`tools/audio/generate_audio.py`).
- **Musiques** (`assets/audio/music/`) : **Kevin MacLeod (incompetech.com)**, licence **Creative Commons Attribution 4.0**
  (https://creativecommons.org/licenses/by/4.0/), converties en OGG (aucune autre modification) :
  « Thatched Villagers » (villageois), « Village Consort » (consort_du_village), « Minstrel Guild » (guilde_des_menestrels),
  « Teller of the Tales » (conteur), « Folk Round » (ronde), « Achaidh Cheide » (achaidh_cheide), « Pippin the Hunchback » (pippin).
