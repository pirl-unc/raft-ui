#!/usr/bin/env bash

# Sync the hosted UI pages from RAFT.
#
# RAFT is canonical: the pages under src/raft/ui/static are the source of
# truth, and this repo is a published copy. Never edit the synced files here --
# the next sync will overwrite them. Fix them in RAFT and re-run this script.
#
# Files this script does NOT manage, because they exist only for the hosted
# site and have no counterpart in RAFT:
#   index.html        GitHub Pages landing page
#   lens-viewer.html  standalone LENS viewer bundle
#
# Historical note: raft-viewer.html used to be split here into a smaller HTML
# file plus an external raft-viewer-demo-data.js, while RAFT kept the demo data
# inlined. That split saved ~31 KB of the ~1.28 MB total (2.5%), and it meant a
# straight copy would silently orphan the data file, so this script was left
# unrun and the two copies drifted apart in both directions. The hosted copy
# now matches RAFT exactly.

set -euo pipefail

SOURCE_DIR="${SOURCE_DIR:-$HOME/dev/raft/src/raft/ui/static}"
TARGET_DIR="${TARGET_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

SYNCED_FILES=(
  "raft-viewer.html"
  "raft-cloud-launcher.html"
  "raft-config-generator.html"
  "raft-manifest-generator.html"
)

# Third-party runtime libraries, vendored so the pages work without internet
# access. The pages reference these by relative path, so the directory must
# travel with them.
SYNCED_DIRS=(
  "vendor"
)

# Superseded by the inlined demo data in raft-viewer.html.
OBSOLETE_FILES=(
  "raft-viewer-demo-data.js"
)

if [[ ! -d "$SOURCE_DIR" ]]; then
  printf 'Source directory not found: %s\n' "$SOURCE_DIR" >&2
  printf 'Set SOURCE_DIR to your RAFT checkout, e.g.\n' >&2
  printf '  SOURCE_DIR=/path/to/raft/src/raft/ui/static %s\n' "${BASH_SOURCE[0]}" >&2
  exit 1
fi

for name in "${SYNCED_FILES[@]}"; do
  if [[ ! -f "$SOURCE_DIR/$name" ]]; then
    printf 'Missing in RAFT, refusing to sync: %s\n' "$SOURCE_DIR/$name" >&2
    exit 1
  fi
done

changed=0
for name in "${SYNCED_FILES[@]}"; do
  if [[ -f "$TARGET_DIR/$name" ]] && cmp -s "$SOURCE_DIR/$name" "$TARGET_DIR/$name"; then
    printf '  unchanged  %s\n' "$name"
  else
    cp "$SOURCE_DIR/$name" "$TARGET_DIR/$name"
    printf '  updated    %s\n' "$name"
    changed=$((changed + 1))
  fi
done

for name in "${SYNCED_DIRS[@]}"; do
  if [[ ! -d "$SOURCE_DIR/$name" ]]; then
    printf 'Missing in RAFT, refusing to sync: %s/\n' "$SOURCE_DIR/$name" >&2
    exit 1
  fi
  if [[ -d "$TARGET_DIR/$name" ]] && diff -rq "$SOURCE_DIR/$name" "$TARGET_DIR/$name" >/dev/null 2>&1; then
    printf '  unchanged  %s/\n' "$name"
  else
    rm -rf "${TARGET_DIR:?}/$name"
    cp -R "$SOURCE_DIR/$name" "$TARGET_DIR/$name"
    printf '  updated    %s/ (%s files)\n' "$name" "$(find "$TARGET_DIR/$name" -type f | wc -l)"
    changed=$((changed + 1))
  fi
done

for name in "${OBSOLETE_FILES[@]}"; do
  if [[ -f "$TARGET_DIR/$name" ]]; then
    rm "$TARGET_DIR/$name"
    printf '  removed    %s (obsolete)\n' "$name"
    changed=$((changed + 1))
  fi
done

# A silent no-op sync would be indistinguishable from a broken one.
for name in "${SYNCED_FILES[@]}"; do
  if ! cmp -s "$SOURCE_DIR/$name" "$TARGET_DIR/$name"; then
    printf 'Verification failed: %s still differs from RAFT\n' "$name" >&2
    exit 1
  fi
done

for name in "${SYNCED_DIRS[@]}"; do
  if ! diff -rq "$SOURCE_DIR/$name" "$TARGET_DIR/$name" >/dev/null 2>&1; then
    printf 'Verification failed: %s/ still differs from RAFT\n' "$name" >&2
    exit 1
  fi
done

# The pages load these by relative path, so a missing one breaks the page
# silently at runtime rather than at sync time.
for page in "${SYNCED_FILES[@]}"; do
  while read -r ref; do
    [[ -z "$ref" ]] && continue
    if [[ ! -f "$TARGET_DIR/$ref" ]]; then
      printf 'Verification failed: %s references missing asset %s\n' "$page" "$ref" >&2
      exit 1
    fi
  done < <(grep -oh 'vendor/[A-Za-z0-9._-]*' "$TARGET_DIR/$page" 2>/dev/null | sort -u)
done

printf '\nSynced %d file(s) from %s\n' "$changed" "$SOURCE_DIR"
printf 'All %d managed files verified identical to RAFT.\n' "${#SYNCED_FILES[@]}"
