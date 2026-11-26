#!/usr/bin/env bash
# Régénère toutes les planches de style : atlas -> rendus Blender -> planches PNG dans docs/style/.
set -euo pipefail
cd "$(dirname "$0")/../.."
B="${BLENDER:-blender}"
python3 tools/style/atlas.py build/style
"$B" -b -P tools/style/render_lutins.py -- build/style/renders tout
"$B" -b -P tools/style/render_blocs.py -- build/style build/style/renders
"$B" -b -P tools/style/render_scene.py -- build/style build/style/renders A
"$B" -b -P tools/style/render_orcs.py -- build/style/renders
python3 tools/style/compose_planches.py build/style/renders build/style docs/style
python3 tools/style/compose_ui.py build/style/renders docs/style
