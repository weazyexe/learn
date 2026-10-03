#!/usr/bin/env bash
# Copy a verified PNG into the viz folder under a unique name.
# Usage: publish.sh <rendered.png> <viz-dir> <slug>
# Prints:  filename: viz-<slug>-<timestamp>.png
#          path: <absolute path>
# If <rendered.png> lives under <viz-dir>/.work/, that work folder is removed afterwards.
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "usage: $(basename "$0") <rendered.png> <viz-dir> <slug>" >&2
  exit 2
fi
png="$1"
dir="$2"
[ -f "$png" ] || { echo "error: no such file: $png" >&2; exit 2; }

slug="$(printf '%s' "$3" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
[ -n "$slug" ] || slug="viz"

mkdir -p "$dir"
dir="$(cd "$dir" && pwd)"
ts="$(date +%s)"
name="viz-$slug-$ts.png"
n=1
while [ -e "$dir/$name" ]; do name="viz-$slug-$ts-$n.png"; n=$((n + 1)); done
cp "$png" "$dir/$name"
work_root="$dir/.work/"
png_dir="$(cd "$(dirname "$png")" && pwd)/"
case "$png_dir" in
  "$work_root"?*)
    rel="${png_dir#"$work_root"}"
    rm -rf "${work_root:?}${rel%%/*}"
    rmdir "$work_root" 2>/dev/null || true
    ;;
esac
echo "filename: $name"
echo "path: $dir/$name"
