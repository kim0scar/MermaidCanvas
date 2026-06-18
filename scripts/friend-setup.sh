#!/bin/bash
# friend-setup.sh — gör en uppackad Visuali2e-källkopia byggbar på en VÄNS Mac/Apple-ID.
# Byter Kims Team-ID + bundle-prefix i project.yml och regenererar Xcode-projektet
# (i rätt ordning — xcodegen körs EFTER bytet, annars bygger Xcode mot Kims team).
#
# Körs i repo-roten EFTER att ZIP:en packats upp:
#   scripts/friend-setup.sh <TEAM_ID> <BUNDLE_PREFIX>
# Ex:  scripts/friend-setup.sh ABCDE12345 com.bjorn
set -euo pipefail

TEAM="${1:-}"
BUNDLE="${2:-}"
PROJ="app/MermaidCanvas/project.yml"

if [ -z "$TEAM" ] || [ -z "$BUNDLE" ]; then
  echo "Användning: scripts/friend-setup.sh <TEAM_ID> <BUNDLE_PREFIX>"
  echo "  <TEAM_ID>        ditt Apple Team ID (10 tecken). Hitta i Xcode →"
  echo "                   Settings → Accounts → Manage Certificates (id i parentes)."
  echo "  <BUNDLE_PREFIX>  t.ex. com.dittnamn  (ersätter com.kimlundqvist)"
  exit 1
fi
[ -f "$PROJ" ] || { echo "Hittar inte $PROJ — kör från repo-roten (mappen där app/ ligger)."; exit 1; }

if ! printf '%s' "$TEAM" | grep -qE '^[A-Z0-9]{10}$'; then
  echo "VARNING: '$TEAM' ser inte ut som ett 10-teckens Team ID — fortsätter ändå."
fi

echo "Byter Team-ID (SFXR8MV6MP → $TEAM) och bundle (com.kimlundqvist → $BUNDLE) i $PROJ ..."
sed -i '' "s/SFXR8MV6MP/$TEAM/g; s/com\.kimlundqvist/$BUNDLE/g" "$PROJ"

echo "Regenererar Xcode-projektet (xcodegen) ..."
( cd app/MermaidCanvas && xcodegen generate )

echo ""
echo "✅ Klart. Projektet använder nu ditt team ($TEAM) och bundle ($BUNDLE.mermaidcanvas)."
echo "   Nästa: bygg + installera enligt INSTALL-FÖR-VÄNNEN.md (steg 4–6)."
