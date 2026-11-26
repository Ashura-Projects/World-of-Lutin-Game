#!/usr/bin/env bash
# Régénère les planches de style v2 : atlas -> rendus Blender -> planches PNG dans docs/style/.
# (lutin-variantes.png et orcs-apercu.png sont des planches v1 archivées, non régénérées ici.)
set -euo pipefail
cd "$(dirname "$0")/../.."
B="${BLENDER:-blender}"
R=build/style/r2
python3 tools/style/atlas.py build/style
"$B" -b -P tools/style/render_lutins.py -- "$R" tout
"$B" -b -P tools/style/render_blocs.py -- build/style "$R"
"$B" -b -P tools/style/render_scene.py -- build/style "$R" C
python3 tools/style/compose_planches.py "$R" build/style docs/style
python3 tools/style/compose_fiches.py "$R" docs/style
python3 tools/style/compose_menus.py "$R" docs/style
