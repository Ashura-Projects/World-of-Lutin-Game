#!/usr/bin/env bash
# Installe Blender (LTS officielle, archive Linux) si absent. Idempotent.
set -euo pipefail
VER=4.5.3
DIR="$HOME/.local/blender/blender-$VER-linux-x64"
if [ ! -x "$DIR/blender" ]; then
  mkdir -p "$HOME/.local/blender"
  curl -sSL "https://download.blender.org/release/Blender${VER%.*}/blender-$VER-linux-x64.tar.xz" | tar xJ -C "$HOME/.local/blender"
fi
mkdir -p "$HOME/.local/bin"
ln -sf "$DIR/blender" "$HOME/.local/bin/blender"
"$HOME/.local/bin/blender" -b --version | head -1
