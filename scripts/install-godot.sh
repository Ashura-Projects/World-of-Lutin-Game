#!/usr/bin/env bash
# Installe Godot (version de .godot-version) + modèles d'export si absents. Idempotent, silencieux si déjà présent.
set -euo pipefail
cd "$(dirname "$0")/.."
VER="$(cat .godot-version)"
DIR="$HOME/.local/godot/$VER"
BIN="$DIR/Godot_v${VER}-stable_linux.x86_64"
if [ ! -x "$BIN" ]; then
  mkdir -p "$DIR"
  curl -sSL -o /tmp/godot.zip "https://github.com/godotengine/godot/releases/download/${VER}-stable/Godot_v${VER}-stable_linux.x86_64.zip"
  unzip -qo /tmp/godot.zip -d "$DIR" && rm -f /tmp/godot.zip
fi
mkdir -p "$HOME/.local/bin"
ln -sf "$BIN" "$HOME/.local/bin/godot"
# gdtoolkit (gdformat / gdlint)
command -v gdlint >/dev/null 2>&1 || pip install -q "gdtoolkit==4.*" >/dev/null 2>&1 || true
"$HOME/.local/bin/godot" --headless --version 2>/dev/null | head -1
