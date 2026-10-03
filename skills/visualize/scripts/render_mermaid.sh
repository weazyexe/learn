#!/usr/bin/env bash
# Render a Mermaid source file to a PNG (2x scale, white background).
# Usage: render_mermaid.sh <input.mmd> <output.png>
# Uses `mmdc` if installed, otherwise `npx -y @mermaid-js/mermaid-cli`.
# Reuses an installed Chrome/Chromium when found so puppeteer skips its download.
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $(basename "$0") <input.mmd> <output.png>" >&2
  exit 2
fi
in="$1"
out="$2"
[ -f "$in" ] || { echo "error: no such file: $in" >&2; exit 2; }

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:$PATH"

chrome=""
for c in \
  "${PUPPETEER_EXECUTABLE_PATH:-}" \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "$(command -v google-chrome 2>/dev/null || true)" \
  "$(command -v chromium 2>/dev/null || true)" \
  "$(command -v chromium-browser 2>/dev/null || true)"; do
  if [ -n "$c" ] && [ -x "$c" ]; then chrome="$c"; break; fi
done

work="$(mktemp -d "${TMPDIR:-/tmp}/learn-mmdc.XXXXXX")"
trap 'rm -rf "$work"' EXIT
cfg="$work/puppeteer.json"
if [ -n "$chrome" ]; then
  export PUPPETEER_SKIP_DOWNLOAD=1
  printf '{"executablePath":"%s","args":["--no-sandbox"]}\n' "$chrome" > "$cfg"
else
  printf '{"args":["--no-sandbox"]}\n' > "$cfg"
fi

if command -v mmdc >/dev/null 2>&1; then
  mmdc_cmd=(mmdc)
elif command -v npx >/dev/null 2>&1; then
  mmdc_cmd=(npx -y @mermaid-js/mermaid-cli)
else
  echo "error: need mmdc or npx (install Node.js, or: npm i -g @mermaid-js/mermaid-cli)" >&2
  exit 127
fi

mkdir -p "$(dirname "$out")"
rm -f "$out"
if ! "${mmdc_cmd[@]}" -i "$in" -o "$out" -p "$cfg" -s 2 -b white -q 2>"$work/err"; then
  echo "Mermaid render FAILED, no image produced. Fix the source and re-render." >&2
  grep -vE '^[[:space:]]+at |^Parser\.|mermaid-cli-intercept|node_modules/' "$work/err" | tail -n 30 >&2
  exit 1
fi
[ -f "$out" ] || { echo "Mermaid render FAILED: mmdc exited 0 but wrote no file" >&2; exit 1; }
echo "$out"
