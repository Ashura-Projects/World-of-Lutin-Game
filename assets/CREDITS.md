# Crédits des assets

## Planches de style (docs/style/)
Aucun asset externe : tout est **fabriqué par script** pour ce projet.
- Lutins, orcs, arbres, outils : modèles low-poly originaux construits à partir de primitives dans **Blender 4.5 LTS** (GPL, outil — les rendus ne sont pas soumis à la GPL). Scripts : `tools/style/`.
- Textures des blocs : pixel art 32×32 généré par `tools/style/atlas.py` (Pillow).
- Police des maquettes : **DejaVu Sans / DejaVu Serif** — licence libre Bitstream Vera / domaine public (https://dejavu-fonts.github.io/).
- Police des titres : **Cinzel** (The Cinzel Project Authors) — SIL Open Font License 1.1, fichiers `assets/fonts/` (licence : `assets/fonts/OFL-Cinzel.txt`), obtenue via le paquet npm @fontsource/cinzel.

## Jeu
- `assets/ui/title_bg.jpg`, `assets/ui/icon.png` : rendus Blender faits pour ce projet (`tools/style/`).
- Outil de tests **GUT 9.7.1** (`addons/gut/`, licence MIT, non inclus dans l'APK).
- **Musiques, ambiances et bruitages** (`assets/audio/`) : générés par synthèse pour ce projet (`tools/audio/generate_audio.py`), aucun échantillon externe.
