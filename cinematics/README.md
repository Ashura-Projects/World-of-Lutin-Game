# Cinématiques dessinées — World of Lutins (by Ashura)

Rendu avec Remotion (React). Lutins, orcs et décors sont dessinés en SVG (`src/Characters.jsx`, `src/Scenery.jsx`) ;
le logo d'Ashura se dessine puis brûle (`src/LogoBurn.jsx`) ; scènes dans `src/Scenes.jsx`, chapitres de la
Campagne dans `src/chapters.js`.

    npm install
    node render.mjs all          # Intro + Chapitre-1..7 (out/*.mp4)
    node render.mjs Intro --still 250   # une image pour vérifier
    ../tools/cinematics_export.sh        # conversion Ogg Theora → assets/cinematics/

Musiques : Kevin MacLeod (incompetech.com), CC BY 4.0.
