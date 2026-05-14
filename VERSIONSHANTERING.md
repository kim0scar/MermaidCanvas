# VERSIONSHANTERING.md

Exakt checklista som Claude Code följer **vid varje deploy** till iPhone. En deploy = en ny version.

## Vad är en version?

En version skapas varje gång appen byggs och installeras på iPhone. **Inte** vid varje liten kod-iteration under pågående arbete.

Versionsnummer: enkelt löpnummer `v1`, `v2`, `v3`, …

## Checklista vid varje deploy

Kör i ordning. Hoppa inte över steg.

### 1. Kontrollera att git är rent

```bash
cd "/Users/kim/2e Mermaid Code"
git status
```

Allt ska vara stagat eller commitat innan deploy startar.

### 2. Bygg och deploya till iPhone

Följ `Start för ios appar Kim.md` (Steg 1A → Steg 2 → Steg 3 för native Swift, eller motsvarande för Godot).
Verifiera att appen faktiskt **startar** på iPhone innan du går vidare.

### 3. Arkivera nuvarande arkitektur

Hitta nästa versionsnummer `N` (titta i `arkiv/` för senast använda + 1).

```bash
mv ARKITEKTUR-MERMAID.md "arkiv/ARKITEKTUR-MERMAID-v$N.md"
```

### 4. Skapa ny ARKITEKTUR-MERMAID.md

Spegla nuvarande kod. Två obligatoriska delar:
1. Ett `mermaid graph TD`-diagram över appens komponenter och flöden.
2. En tabell: `Komponent | Fil | Ansvar`.

Lägg datum + versionsnummer överst.

### 5. Commit

```bash
git add -A
git commit -m "vN: <vad ändrades på svenska>"
```

Exempel: `git commit -m "v3: la till stöd för att rita pilar mellan former"`

### 6. Pusha till GitHub

```bash
git push
```

### 7. Rapportera till Kim

Säg exakt: **"Version vN deployad och pushad."**
Plus en mening om vad som ändrades.

## Rollback om något gick sönder

Om appen kraschar eller funktionalitet försvann i nyss deployade version:

```bash
git revert HEAD
# Bygg om och deploya föregående version enligt Start för ios appar Kim.md
```

Spegla rollbacken: skapa en ny `ARKITEKTUR-MERMAID.md` som matchar den återställda koden, och döp om den trasiga i arkivet till `ARKITEKTUR-MERMAID-vN-trasig.md` så historiken behålls.
