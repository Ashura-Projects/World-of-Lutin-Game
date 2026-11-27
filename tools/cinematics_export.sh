#!/usr/bin/env bash
# Convertit les cinématiques rendues par Remotion (cinematics/out/*.mp4) en Ogg Theora pour Godot.
# Usage : (cd cinematics && npm install && node render.mjs all) puis tools/cinematics_export.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/cinematics
for f in cinematics/out/*.mp4; do
	name=$(basename "$f" .mp4 | tr 'A-Z' 'a-z' | tr '-' '_')
	ffmpeg -v error -y -i "$f" -c:v libtheora -q:v 6 -c:a libvorbis -q:a 4 "assets/cinematics/$name.ogv"
	echo "$name.ogv $(stat -c%s "assets/cinematics/$name.ogv")"
done
