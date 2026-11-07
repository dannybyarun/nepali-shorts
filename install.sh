#!/usr/bin/env sh
set -eu
dest="${1:-$HOME/.config/opencode/skills/nepali-shorts}"
mkdir -p "$dest"
cp "$(dirname "$0")/SKILL.md" "$dest/SKILL.md"
printf 'Installed nepali-shorts skill to %s\n' "$dest"
