#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR="${SOURCE_DIR:-$HOME/dev/raft/ui}"
TARGET_DIR="${TARGET_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

FILES=(
  "config-generator.html"
  "raft-viewer.html"
  "manifest-generator.html"
)

for file in "${FILES[@]}"; do
  cp "$SOURCE_DIR/$file" "$TARGET_DIR/$file"
done

printf 'Synced %s file(s) from %s to %s\n' "${#FILES[@]}" "$SOURCE_DIR" "$TARGET_DIR"
