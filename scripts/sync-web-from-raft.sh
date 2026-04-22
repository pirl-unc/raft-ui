#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR="${SOURCE_DIR:-$HOME/dev/raft/src/raft/ui/static}"
TARGET_DIR="${TARGET_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

copy_from_raft() {
  local src="$1"
  cp "$SOURCE_DIR/$src" "$TARGET_DIR/$src"
}

copy_from_raft "raft-viewer.html"
copy_from_raft "raft-cloud-launcher.html"
copy_from_raft "raft-config-generator.html"
copy_from_raft "raft-manifest-generator.html"

printf 'Synced hosted UI files from %s to %s
' "$SOURCE_DIR" "$TARGET_DIR"