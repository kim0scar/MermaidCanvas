#!/bin/bash
# deploy-mac.sh — bygg om Mac-appen (MermaidCanvasMac) till nuvarande AppVersion
# och installera den i /Applications/Visuali2e.app. SJÄLVVERIFIERANDE: skriptet
# faller (exit 1) om den installerade versionen inte matchar källan, om appen inte
# startar, eller om den kraschar vid start.
#
# Varför finns detta? Mac-appen delar all kod med iPhone-appen men byggs/installeras
# separat. iPhone-deployen rör den INTE → den kunde tyst halka efter (var 1.0 medan
# iPhone var 1.5.1). Den här grinden gör Mac-deployen omöjlig att glömma och omöjlig
# att råka deploya fel version. Se ARKITEKTUR-DUAL-PLATFORM.md + VERSIONSHANTERING.md.
#
# Körs av: VERSIONSHANTERING.md deploy-steget (och scripts/deploy.sh som kör iPhone+Mac).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/app/MermaidCanvas"
DEST="/Applications/Visuali2e.app"
PRODUCT_NAME="MermaidCanvasMac.app"

# 1. Läs sanningskällan för versionen.
AV_FILE="$APP_DIR/Sources/App/AppVersion.swift"
VERSION="$(grep -oE 'version[[:space:]]*:[[:space:]]*String[[:space:]]*=[[:space:]]*"[^"]+"' "$AV_FILE" | grep -oE '"[^"]+"' | tr -d '"')"
if [ -z "$VERSION" ]; then
  echo "🔴 deploy-mac: hittar inte AppVersion.version i $AV_FILE" >&2
  exit 1
fi
echo "▶︎ deploy-mac: målversion $VERSION (från AppVersion.swift)"

# 2. Regenerera projektet (project.yml → xcodeproj) så Mac-targeten är aktuell.
if command -v xcodegen >/dev/null 2>&1; then
  ( cd "$APP_DIR" && xcodegen generate >/dev/null )
  echo "✓ xcodegen: projektet regenererat"
fi

# 3. Bygg Release för macOS i en egen byggmapp (förorenar inte repo:t).
BUILD_DIR="$(mktemp -d /tmp/visuali2e-mac-build.XXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT
echo "▶︎ bygger MermaidCanvasMac (Release)…"
( cd "$APP_DIR" && xcodebuild -scheme MermaidCanvasMac -configuration Release \
    -destination 'platform=macOS' -derivedDataPath "$BUILD_DIR" build ) \
  > "$BUILD_DIR/build.log" 2>&1 || { echo "🔴 deploy-mac: bygget misslyckades. Logg: $BUILD_DIR/build.log" >&2; tail -20 "$BUILD_DIR/build.log" >&2; exit 1; }
PRODUCT="$BUILD_DIR/Build/Products/Release/$PRODUCT_NAME"
[ -d "$PRODUCT" ] || { echo "🔴 deploy-mac: byggprodukt saknas: $PRODUCT" >&2; exit 1; }
echo "✓ bygget klart"

# 4. Markör för kraschlogg-koll (allt nytt EFTER denna fil = från denna start).
MARKER="$BUILD_DIR/marker"; touch "$MARKER"

# 5. Avsluta körande instanser och ersätt /Applications-appen.
pkill -f "MermaidCanvasMac" 2>/dev/null || true
pkill -f "Visuali2e" 2>/dev/null || true
sleep 1
rm -rf "$DEST"
cp -R "$PRODUCT" "$DEST"
echo "✓ installerad i $DEST"

# 6. VERIFIERA: installerad version == källan.
INSTALLED="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$DEST/Contents/Info.plist" 2>/dev/null || true)"
if [ "$INSTALLED" != "$VERSION" ]; then
  echo "🔴 deploy-mac: installerad version '$INSTALLED' ≠ AppVersion '$VERSION'." >&2
  exit 1
fi
echo "✓ version matchar: $INSTALLED"

# 7. VERIFIERA: appen startar och lever.
open "$DEST"
sleep 4
if ! pgrep -f "Visuali2e.app/Contents/MacOS" >/dev/null 2>&1; then
  echo "🔴 deploy-mac: appen startade inte (eller kraschade direkt)." >&2
  exit 1
fi
echo "✓ appen lever"

# 8. VERIFIERA: inga nya kraschloggar sedan starten.
sleep 2
CRASHES="$(find "$HOME/Library/Logs/DiagnosticReports" -iname 'MermaidCanvasMac*' -newer "$MARKER" 2>/dev/null || true)"
if [ -n "$CRASHES" ]; then
  echo "🔴 deploy-mac: nya kraschloggar efter start:" >&2
  echo "$CRASHES" >&2
  exit 1
fi
echo "✓ inga kraschloggar"

echo "✅ deploy-mac: Visuali2e.app $VERSION installerad i /Applications, körs, ren."
