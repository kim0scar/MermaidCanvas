#!/bin/bash
# check-friend-package.sh — vän-paketets bygg-väg får inte tyst bli obyggbar (Hål 4).
#
# En vän får käll-ZIP:en (git archive HEAD) + INSTALL-FÖR-VÄNNEN.md + friend-setup.sh.
# friend-setup.sh byter Kims Team-ID + bundle-prefix i project.yml via `sed`. Om de
# tokens INTE längre finns i project.yml gör seden TYST ingenting → vännens bygge
# använder Kims team och misslyckas. INSTALL-guiden hårdkodar dessutom scheme-namnet.
# Den här grinden HÄRLEDER sanningen ur project.yml och asserterar att vän-filerna
# fortfarande stämmer. En grep-koll, < 0,1 s.
#
# Körs av: pre-commit (när project.yml/vän-filerna ändras), deploy-grinden, Björn-skillen.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="$ROOT/app/MermaidCanvas/project.yml"
SETUP="$ROOT/scripts/friend-setup.sh"
GUIDE="$ROOT/INSTALL-FÖR-VÄNNEN.md"
fail=0
note() { echo "🔴 vän-paket: $1" >&2; fail=1; }

for f in "$PROJ" "$SETUP" "$GUIDE"; do
  [ -f "$f" ] || { echo "🔴 vän-paket: saknar $f" >&2; exit 1; }
done

# Sanning ur project.yml (källan för bygg-konfig).
TEAM="$(awk '/DEVELOPMENT_TEAM:/{print $2; exit}' "$PROJ")"
PREFIX="$(awk '/PRODUCT_BUNDLE_IDENTIFIER:/{print $2; exit}' "$PROJ" | grep -oE 'com\.[a-z]+' | head -1)"
SCHEME="$(grep -oE '\-scheme[[:space:]]+[A-Za-z0-9]+' "$GUIDE" | awk '{print $2}' | head -1)"

# 1. friend-setup.sh:s sed måste byta exakt de tokens project.yml har — annars no-op.
[ -n "$TEAM" ]   && grep -q "$TEAM" "$SETUP"   || note "friend-setup.sh byter inte Team-ID '$TEAM' (sed:en skulle träffa noll → vännens bygge använder Kims team)."
[ -n "$PREFIX" ] && grep -q "$PREFIX" "$SETUP" || note "friend-setup.sh byter inte bundle-prefix '$PREFIX' (sed no-op → fel bundle)."

# 2. Scheme-namnet INSTALL-guiden bygger måste finnas som target i project.yml.
[ -n "$SCHEME" ] && grep -qE "^[[:space:]]+${SCHEME}:" "$PROJ" || note "INSTALL-FÖR-VÄNNEN.md bygger scheme '$SCHEME' som inte finns i project.yml."

if [ "$fail" -ne 0 ]; then
  echo "   → vän-ZIP:en (git archive HEAD) skulle paketera en obyggbar guide. Synka vän-filerna med project.yml." >&2
  exit 1
fi
echo "✅ vän-paket: INSTALL-guide + friend-setup.sh stämmer med project.yml (Team $TEAM · $PREFIX · scheme $SCHEME)."
