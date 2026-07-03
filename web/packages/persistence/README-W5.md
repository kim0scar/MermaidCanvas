# README-W5 — koppla in molnet (Supabase)

Detta paket är GRUNDEN. Allt fungerar redan lokalt (`LocalCanvasStore`) och mot mock i testerna.
I steg W5 pluggas riktiga Supabase in. Så här gör Kim då — steg för steg.

## 1. Skapa kontot (gratis)
1. Gå till https://supabase.com → "Start your project" → logga in med GitHub (`kim0scar`).
2. Skapa nytt projekt: namn `visuali2e`, region `eu-north-1 (Stockholm)`.
3. Databas-lösenordet: spara i lösenordshanteraren. Det behövs nästan aldrig sen.

## 2. Kör schemat
1. Öppna projektet → **SQL Editor** i vänstermenyn.
2. Klistra in HELA innehållet i `sql/schema.sql` → tryck **Run**.
3. Grönt "Success" = klart. Tabellerna `files` + `shares` finns nu, med RLS (radlåsen) på.

## 3. Slå på e-post-inloggning
1. **Authentication → Providers** → Email: på.
2. Inga lösenord behövs — appen loggar in med engångskod/magisk länk (`signInWithOtp`).

## 4. Hämta nycklarna
1. **Project Settings → API.**
2. Kopiera två värden:
   - Project URL → env-namn `VITE_SUPABASE_URL`
   - anon public → env-namn `VITE_SUPABASE_ANON_KEY`
3. Lokalt: lägg dem i appens `.env.local`. Live: samma namn i Cloudflare Pages → Settings → Environment variables.

## 5. Vad som ALDRIG behövs
- **`service_role`-nyckeln ska ALDRIG in i klienten, git eller Cloudflare.** Den kringgår RLS (låset).
- anon-nyckeln är byggd för att vara publik — RLS-policyerna är själva skyddet.

## 6. Koden (görs av Claude i W5)
- `npm install @supabase/supabase-js` (första nya beroendet).
- `createClient(url, anonKey)` → in i `new SupabaseCanvasStore(client)` (klienten uppfyller `SupabaseLikeClient`).
- En delad länk öppnas med en klient som skickar headern `x-share-token: <token>` — det är den headern RLS-policyerna läser. Så kan även en vän utan konto öppna/redigera exakt den delade filen.
- Offline/utan konto: `LocalCanvasStore` är fallbacken — samma `CanvasStore`-interface, UI:t märker ingen skillnad.

## Varför en text-kolumn (inte Storage/blob)?
- Filerna är små markdown-texter (KB) och texten är KANONISK — en `text`-kolumn i Postgres lagrar UTF-8 exakt, byte-identiskt (noll-avvikelse-garantin).
- RLS skyddar per rad — delnings-reglerna sitter på samma rad som innehållet.
- Storage hade gett två anrop (metadata + blob), egna storage-policies och ingen vinst för KB-stora filer.
