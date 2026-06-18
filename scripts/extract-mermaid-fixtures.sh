#!/bin/bash
# Steg 7 — regenerera mermaid-fixtures från appens FAKTISKA generator-output.
#
# Kör MermaidConformanceCorpusTests, fångar base64-raderna (@@@MMD64:namn:...) ur
# xcodebuild-loggen och avkodar dem till scripts/mermaid-fixtures/<namn>.mmd.
# Kör sedan `node scripts/mermaid-conformance.mjs` för att validera mot riktig mermaid.
#
# Kör om detta varje gång MermaidGenerator ändrar hur former/kanter skrivs.
set -euo pipefail

REPO="/Users/kim/2e Mermaid Code"
PROJ="$REPO/app/MermaidCanvas/MermaidCanvas.xcodeproj"
SCHEME="MermaidCanvas"
OUT_DIR="$REPO/scripts/mermaid-fixtures"
LOG="$(mktemp -t mmdfixtures)"

# Bootad iPhone-sim, annars första TILLGÄNGLIGA iPhone-sim (modell-agnostiskt).
UDID="$(xcrun simctl list devices booted | grep -m1 'iPhone' | grep -oE '[0-9A-Fa-f-]{36}' || true)"
if [ -z "$UDID" ]; then
  UDID="$(xcrun simctl list devices available | grep -m1 'iPhone' | grep -oE '[0-9A-Fa-f-]{36}' || true)"
fi
if [ -z "$UDID" ]; then
  echo "✗ Hittade ingen iPhone-simulator. Lista: xcrun simctl list devices"; exit 1
fi
DEST="platform=iOS Simulator,id=$UDID"

echo "▶︎ Kör korpus-testet (destination: $DEST) …"
xcodebuild test \
  -project "$PROJ" -scheme "$SCHEME" \
  -destination "$DEST" \
  -only-testing:MermaidCanvasUnitTests/MermaidConformanceCorpusTests \
  > "$LOG" 2>&1 || { echo "✗ xcodebuild test misslyckades. Slut på loggen:"; tail -30 "$LOG"; exit 1; }

mkdir -p "$OUT_DIR"
COUNT=0
# En rad per fixtur: @@@MMD64:<namn>:<base64>
while IFS= read -r line; do
  name="$(printf '%s' "$line" | sed -E 's/^.*@@@MMD64:([^:]+):.*/\1/')"
  b64="$(printf '%s' "$line"  | sed -E 's/^.*@@@MMD64:[^:]+:([A-Za-z0-9+/=]+).*/\1/')"
  printf '%s' "$b64" | base64 -D > "$OUT_DIR/$name.mmd"
  echo "  ✎ $name.mmd"
  COUNT=$((COUNT + 1))
done < <(grep -oE '@@@MMD64:[^:]+:[A-Za-z0-9+/=]+' "$LOG" | sort -u)

if [ "$COUNT" -eq 0 ]; then
  echo "✗ Hittade inga @@@MMD64-rader i testutskriften. Slut på loggen:"; tail -30 "$LOG"; exit 1
fi
echo "✓ $COUNT fixtures skrivna till $OUT_DIR"
echo
echo "▶︎ Validerar mot riktig mermaid …"
node "$REPO/scripts/mermaid-conformance.mjs"
