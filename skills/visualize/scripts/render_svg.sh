#!/usr/bin/env bash
# Render an SVG file to a PNG at 2x.
# Usage: render_svg.sh <input.svg> <output.png>
# Uses rsvg-convert (librsvg), falling back to ImageMagick `magick`.
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $(basename "$0") <input.svg> <output.png>" >&2
  exit 2
fi
in="$1"
out="$2"
[ -f "$in" ] || { echo "error: no such file: $in" >&2; exit 2; }

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:$PATH"
mkdir -p "$(dirname "$out")"
rm -f "$out"

err="$(mktemp "${TMPDIR:-/tmp}/learn-svg.XXXXXX")"
trap 'rm -f "$err"' EXIT

if command -v rsvg-convert >/dev/null 2>&1; then
  if rsvg-convert -z 2 -b white "$in" -o "$out" 2>"$err" && [ -f "$out" ]; then
    echo "$out"; exit 0
  fi
fi
if command -v magick >/dev/null 2>&1; then
  if magick -density 192 -background white "$in" -flatten "$out" 2>>"$err" && [ -f "$out" ]; then
    echo "$out"; exit 0
  fi
fi

if ! command -v rsvg-convert >/dev/null 2>&1 && ! command -v magick >/dev/null 2>&1; then
  echo "error: need rsvg-convert (brew install librsvg) or ImageMagick (brew install imagemagick)" >&2
  exit 127
fi
echo "SVG render FAILED, no image produced. Fix the source and re-render." >&2
tail -n 30 "$err" >&2
exit 1
