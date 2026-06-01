#!/bin/bash
# ux-driver.sh — tunt verktygslager ovanpå idb för persona-testning.
# Ger en persona-agent (eller CLI-bryggan) enkla, robusta kommandon för att
# DRIVA MermaidCanvas i simulatorn och SE resultatet.
#
# Designprincip: agenten arbetar SEMANTISKT (element via AXLabel) eller via
# normaliserade canvas-koordinater — aldrig råa pixlar den gissat.
#
# Användning:
#   ux-driver.sh <UDID> tree                       → a11y-träd (JSON, element+frames+labels)
#   ux-driver.sh <UDID> labels                     → bara labels + center-koordinater (lättläst)
#   ux-driver.sh <UDID> tap <label>                → tappar mitten av elementet med AXLabel=<label>
#   ux-driver.sh <UDID> tapxy <x> <y>              → tappar pixelkoordinat
#   ux-driver.sh <UDID> double <label>             → dubbeltap
#   ux-driver.sh <UDID> long <label> [sek]         → long-press (default 0.6s)
#   ux-driver.sh <UDID> swipe <x1> <y1> <x2> <y2>  → svep/drag
#   ux-driver.sh <UDID> text "<sträng>"            → skriver text i fokuserat fält
#   ux-driver.sh <UDID> shot <fil.png>             → screenshot
#   ux-driver.sh <UDID> step <namn> <utmapp>       → screenshot + a11y-träd till <utmapp>/<namn>.{png,json}
#   ux-driver.sh <UDID> launch                     → (om)starta appen
#   ux-driver.sh <UDID> reset                      → avsluta appen (rensar canvas-state mellan körningar)
#
# UDID hämtas med:  xcrun simctl list devices booted | grep iPhone
BUNDLE="com.kimlundqvist.mermaidcanvas"
IDB="$(dirname "$0")/idb"
UDID="$1"; CMD="$2"; shift 2 2>/dev/null

frame_center() { # läser /tmp/uxtree.json, skriver "x y" för AXLabel=$1
  python3 -c "
import json,sys
lbl=sys.argv[1]
d=json.load(open('/tmp/uxtree_$UDID.json'))
for e in d:
    if e.get('AXLabel')==lbl:
        f=e['frame']; print(int(f['x']+f['width']/2), int(f['y']+f['height']/2)); break
else:
    sys.exit('AXLabel not found: '+lbl)
" "$1"
}

dump_tree() { "$IDB" ui describe-all --udid "$UDID" 2>/dev/null > "/tmp/uxtree_$UDID.json"; }

case "$CMD" in
  tree)   "$IDB" ui describe-all --udid "$UDID" 2>/dev/null ;;
  labels) dump_tree; python3 -c "
import json
d=json.load(open('/tmp/uxtree_$UDID.json'))
for e in d:
    l=e.get('AXLabel') or e.get('AXIdentifier') or '(ingen)'
    f=e.get('frame',{})
    if f: print(f\"{l:35s} center=({int(f['x']+f['width']/2)},{int(f['y']+f['height']/2)})  {int(f['width'])}x{int(f['height'])}\")
" ;;
  tap)    dump_tree; read X Y < <(frame_center "$1"); "$IDB" ui tap --udid "$UDID" $X $Y && echo "tap $1 ($X,$Y)" ;;
  tapxy)  "$IDB" ui tap --udid "$UDID" "$1" "$2" && echo "tap ($1,$2)" ;;
  double) dump_tree; read X Y < <(frame_center "$1"); "$IDB" ui tap --udid "$UDID" $X $Y; "$IDB" ui tap --udid "$UDID" $X $Y; echo "double $1" ;;
  long)   dump_tree; read X Y < <(frame_center "$1"); "$IDB" ui tap --udid "$UDID" --duration "${2:-0.6}" $X $Y && echo "long $1" ;;
  swipe)  "$IDB" ui swipe --udid "$UDID" "$1" "$2" "$3" "$4" && echo "swipe ($1,$2)->($3,$4)" ;;
  text)   "$IDB" ui text --udid "$UDID" "$1" && echo "text: $1" ;;
  shot)   "$IDB" screenshot --udid "$UDID" "$1" >/dev/null 2>&1 && echo "shot $1" ;;
  step)   mkdir -p "$2"; "$IDB" screenshot --udid "$UDID" "$2/$1.png" >/dev/null 2>&1; "$IDB" ui describe-all --udid "$UDID" 2>/dev/null > "$2/$1.json"; echo "step $1 -> $2/$1.{png,json}" ;;
  launch) xcrun simctl launch "$UDID" "$BUNDLE" ;;
  reset)  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null; echo "terminated" ;;
  *) echo "okänt kommando: $CMD (se headern i ux-driver.sh)"; exit 1 ;;
esac
