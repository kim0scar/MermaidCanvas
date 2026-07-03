-- =============================================================
-- Visuali2e — moln-schema för W5 (Supabase / Postgres)
-- Körs EN gång i Supabase SQL-editorn (se README-W5.md).
--
-- Bärande princip: filens .md-TEXT är kanonisk. Kolumnen `text`
-- lagrar hela filen oförändrad — molnet har aldrig en egen modell.
-- =============================================================

-- FILER: en rad = en .md-fil, ägd av en inloggad användare.
create table public.files (
  id         uuid primary key default gen_random_uuid(),
  owner      uuid not null references auth.users (id) on delete cascade,
  name       text not null,
  text       text not null,          -- HELA .md-filen, byte-identisk
  updated_at timestamptz not null default now()
);

-- DELNINGAR: en rad = en delnings-länk. Token ÄR nyckeln — utan länken når man inget.
create table public.shares (
  token      text primary key,       -- slumpas i klienten (crypto.randomUUID)
  file_id    uuid not null references public.files (id) on delete cascade,
  mode       text not null check (mode in ('read', 'edit')),
  created_by uuid not null references auth.users (id) on delete cascade
);

-- RLS på — utan policy släpps INGENTING igenom.
alter table public.files  enable row level security;
alter table public.shares enable row level security;

-- Delnings-token läses ur HTTP-headern `x-share-token`.
-- (W5: när en delad länk öppnas skapas supabase-klienten med den headern —
--  då kan även en vän UTAN konto läsa/redigera exakt den delade filen.)
create or replace function public.share_token()
returns text
language sql
stable
as $$
  select coalesce(current_setting('request.headers', true)::json ->> 'x-share-token', '')
$$;

-- ---------- FILES: ägaren får allt (CRUD på sina egna filer) ----------
create policy "ägare läser sina filer"   on public.files for select using (owner = auth.uid());
create policy "ägare skapar sina filer"  on public.files for insert with check (owner = auth.uid());
create policy "ägare ändrar sina filer"  on public.files for update
  using (owner = auth.uid()) with check (owner = auth.uid());
create policy "ägare raderar sina filer" on public.files for delete using (owner = auth.uid());

-- ---------- FILES: en giltig token når EXAKT den delade filen ----------
-- Läs-token (read ELLER edit) ger läsning av just den filen — inget annat.
create policy "token läser delad fil" on public.files for select
  using (
    public.share_token() <> ''
    and exists (
      select 1 from public.shares s
      where s.file_id = files.id and s.token = public.share_token()
    )
  );

-- Bara edit-token ger skrivning — och bara på just den filen.
create policy "edit-token skriver delad fil" on public.files for update
  using (
    public.share_token() <> ''
    and exists (
      select 1 from public.shares s
      where s.file_id = files.id and s.token = public.share_token() and s.mode = 'edit'
    )
  )
  with check (
    exists (
      select 1 from public.shares s
      where s.file_id = files.id and s.token = public.share_token() and s.mode = 'edit'
    )
  );

-- ---------- SHARES ----------
-- Bara ägaren kan dela sin egen fil.
create policy "ägare delar sin fil" on public.shares for insert
  with check (
    created_by = auth.uid()
    and exists (select 1 from public.files f where f.id = file_id and f.owner = auth.uid())
  );

-- En delnings-rad syns bara för den som redan HAR token (ingen listning/gissning möjlig)
-- eller för den som skapade den. Andras tokens läcker aldrig.
create policy "token slår upp sin egen delning" on public.shares for select
  using (token = public.share_token() or created_by = auth.uid());

-- Ägaren kan dra tillbaka en delning.
create policy "ägare tar bort sin delning" on public.shares for delete
  using (created_by = auth.uid());
