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

### 1b. Bumpa versionsnumret

Öppna `app/MermaidCanvas/Sources/AppVersion.swift`.
Höj `AppVersion.current` till nästa `vN`. **Detta är enda stället versionsnumret bor.**

Statusen i appen visar denna sträng. Om den inte uppdateras vet inte Kim om han kör nya eller gamla bygget.

### 2. Bygg och deploya till iPhone

Följ `Start för ios appar Kim.md` (Steg 1A → Steg 2 → Steg 3 för native Swift, eller motsvarande för Godot).
Verifiera att appen faktiskt **startar** på iPhone innan du går vidare.

### 3. Arkivera föregående arkitektur

Innan du skriver om `ARKITEKTUR-MERMAID.md`: ta en kopia av den **föregående** versionen och lägg den i `arkiv/`. Föregående version är den som var live *innan* denna deploy — alltså `vN-1`.

```bash
# Exempel om du just bumpat till v13: ARKITEKTUR-MERMAID.md beskrev v12 → snapshot:
cp ARKITEKTUR-MERMAID.md "arkiv/ARKITEKTUR-MERMAID-v12.md"
```

Detta säkerställer att varje deployad version har en frusen snapshot i `arkiv/`.

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
