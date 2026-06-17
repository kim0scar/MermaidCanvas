#!/bin/bash
# see-app.sh — MA-spår C: motorn bakom "titta på appen".
# Bygger (valfritt), installerar, startar MermaidCanvas i en bootad iPhone-simulator
# och tar EN skärmbild som Claude Code kan läsa — plus sökväg till state-dumpen.
# Interaktion (tap/drag/svep + fler skärmbilder) sköts av ux-driver.sh efteråt.
#
# Användning:
#   scripts/see-app.sh [--build] [--scenario <slug>] [--dump] [--shot-only]
#     --build           bygg appen för simulator först (annars används senaste bygget)
#     --scenario <slug>  starta med ett känt canvas-innehåll (-uitest-place-<slug>),
#                        t.ex. 08-arrow-each-shape-type  (se UITestScenarios.swift)
#     --dump            slå på state-dump (-uitest-dump-state) → uitest-state.json
#     --shot-only       starta INTE om appen, ta bara en ny skärmbild av nuläget
#
# Skriver: .see-app/<HHMMSS>/01.png  (+ skriver ut dump-sökväg om --dump)
set -euo pipefail

PROJ_DIR="/Users/kim/2e Mermaid Code/app/MermaidCanvas"
ROOT="/Users/kim/2e Mermaid Code"
BUNDLE="com.kimlundqvist.mermaidcanvas"
SCHEME="MermaidCanvas"
DD="$PROJ_DIR/DerivedData-sim"

DO_BUILD=0; SCENARIO=""; DUMP=0; SHOT_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --build) DO_BUILD=1 ;;
    --scenario) SCENARIO="$2"; shift ;;
    --dump) DUMP=1 ;;
    --shot-only) SHOT_ONLY=1 ;;
    *) echo "okänt argument: $1"; exit 1 ;;
  esac
  shift
done

# Första bootade iPhone-simulatorn.
UDID="$(xcrun simctl list devices booted | grep -m1 'iPhone' | grep -oE '[0-9A-Fa-f-]{36}' || true)"
if [ -z "$UDID" ]; then
  echo "Ingen bootad iPhone-simulator. Starta en med: open -a Simulator"
  exit 1
fi

if [ "$DO_BUILD" = "1" ]; then
  echo "Bygger för simulator…"
  xcodebuild -project "$PROJ_DIR/MermaidCanvas.xcodeproj" -scheme "$SCHEME" \
    -configuration Debug -destination "platform=iOS Simulator,id=$UDID" \
    -derivedDataPath "$DD" build >/tmp/see-app-build.log 2>&1 \
    || { echo "BYGGET MISSLYCKADES — se /tmp/see-app-build.log"; tail -15 /tmp/see-app-build.log; exit 1; }
fi

APP="$DD/Build/Products/Debug-iphonesimulator/MermaidCanvas.app"
[ -d "$APP" ] || { echo "Ingen byggd app hittad ($APP). Kör med --build."; exit 1; }

IDB="$HOME/.local/bin/idb"

if [ "$SHOT_ONLY" != "1" ]; then
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl install "$UDID" "$APP" >/dev/null 2>&1
  ARGS=()
  [ -n "$SCENARIO" ] && ARGS+=("-uitest-place-$SCENARIO")
  [ "$DUMP" = "1" ] && ARGS+=("-uitest-dump-state")
  xcrun simctl launch "$UDID" "$BUNDLE" "${ARGS[@]}" >/dev/null 2>&1
  # Vänta tills verktygsraden ritats (kallstart kan ta flera sekunder) — polla
  # a11y-trädet, ge sedan scenario-innehållet (appliceras 0,3s efter onAppear) en sekund.
  ready=0
  for _ in $(seq 1 24); do
    if "$IDB" ui describe-all --udid "$UDID" 2>/dev/null | grep -q "Visuali2e\|Ångra"; then ready=1; break; fi
    /bin/sleep 0.5
  done
  [ "$ready" = "0" ] && echo "VARNING: verktygsraden syns inte än — skärmbilden kan vara tom."
  /bin/sleep 1.0
fi

TS="$(date +%H%M%S)"
SHOTS="$ROOT/.see-app/$TS"
mkdir -p "$SHOTS"
xcrun simctl io "$UDID" screenshot "$SHOTS/01.png" >/dev/null 2>&1
echo "UDID:        $UDID"
echo "Skärmbild:   $SHOTS/01.png"
if [ "$DUMP" = "1" ] || [ "$SHOT_ONLY" = "1" ]; then
  DUMPFILE="$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data 2>/dev/null)/Documents/uitest-state.json"
  [ -f "$DUMPFILE" ] && echo "State-dump:   $DUMPFILE"
fi
echo "Interaktion: ~/.claude/skills/ux-personas-test/bin/ux-driver.sh $UDID labels|tap <label>|swipe ..."
