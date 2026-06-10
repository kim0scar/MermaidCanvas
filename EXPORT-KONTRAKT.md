# EXPORT-KONTRAKT — den frysta texten i varje exporterad skill-fil (v1)

Master-kopian. Appen bäddar in texten under "KONTRAKT START" ordagrant i varje
exporterad skill-fil (via `SkillExportContract.swift` — synkas för hand vid build).
Tanken: filen ska fungera på VILKEN Claude Code som helst, utan skills, utan projekt.

**Frysregler (bryts aldrig):** texten får ALDRIG innehålla kodstaket (tre backticks),
rader som börjar med dubbla procenttecken, eller HTML-kommentartecken — de krockar
med appens mermaid-parser vid round-trip. Ändringar = ny version (v2) + rad här.

---- KONTRAKT START (v1) ----

Du läser en körbar skill, ritad i appen Visuali2e och exporterad som den här filen.
Filen är hela instruktionen — du behöver inga andra filer, inga skills, inget projekt.

1. Kör flödet i mermaid-blocket nedan nod för nod, i pilarnas riktning. Börja vid
   input-noden. En container (subgraph) är skillens gräns; noderna i den är stegen.
2. Varje nods "prompt:"-kommentar i mermaid-koden är LAGEN — hela instruktionen för
   det steget (Input, Uppgift, Verktyg, Output, PASS, FAIL). Hitta aldrig på saknade
   steg. Saknas något du behöver: stoppa och rapportera exakt vad som saknas.
3. Grind (romb): utvärdera PASS-villkoret PÅ RIKTIGT mot verkliga data — anta aldrig
   PASS. Säg i chatten vilket villkor som utvärderades och utfallet. PASS-pilen vid
   pass, FAIL-pilen vid fail.
4. Manuell koll (åttahörning): STOPPA automatiken. Skriv filen som nodens prompt
   anger: vilket villkor som föll, vad som testats, vad människan kan göra.
   Reparera aldrig tyst. Gissa aldrig.
5. Memory-noder (cylindrar) är överlämnings-filer: skriv ALLTID filen innan nästa
   steg startar, exakt enligt formatet i nodens prompt. Saknar prompten sökväg:
   lägg filen i en mapp med skillens namn, bredvid den här filen.
6. Legend-raderna i mermaid-koden (rader med ordet "legend" följt av kategori och
   text) förklarar vad varje formkategori betyder. Läs dem som översättare innan
   du kör.
7. Vid fel i ett steg: stoppa kedjan, skriv rubriken "FEL" plus vad som hände i den
   fil steget skulle ha producerat, och rapportera. Gissa aldrig konton eller
   lösenord — använd det som redan är inloggat, annars stoppa och fråga.
8. Skillens namn och kedjenummer står i filens frontmatter (skill_name, skill_nr).
   Slutsteget (output-noden) säger vart resultatet ska. Visa alltid resultatet för
   användaren när kedjan är klar.

---- KONTRAKT SLUT ----
