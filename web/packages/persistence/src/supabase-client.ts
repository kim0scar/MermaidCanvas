// MINSTA möjliga bild av supabase-js — bara de metoder SupabaseCanvasStore behöver.
// Riktiga @supabase/supabase-js uppfyller detta i W5 (samma kedjor finns där);
// testerna injicerar en mock. Inget beroende på supabase-js här.

export interface DbError {
  message: string;
  code?: string;
}

export interface DbResult<T> {
  data: T | null;
  error: DbError | null;
}

export type Row = Record<string, unknown>;

/** Query-kedjan: from(...).select/insert/update/delete → ev. eq-filter → await eller .single(). */
export interface QueryBuilder extends PromiseLike<DbResult<Row[]>> {
  select(columns?: string): QueryBuilder;
  insert(row: Row): QueryBuilder;
  update(patch: Row): QueryBuilder;
  delete(): QueryBuilder;
  eq(column: string, value: unknown): QueryBuilder;
  single(): PromiseLike<DbResult<Row>>;
}

export interface AuthUser {
  id: string;
  email?: string;
}

export interface SupabaseLikeClient {
  auth: {
    signInWithOtp(opts: { email: string }): Promise<{ error: DbError | null }>;
    getUser(): Promise<{ data: { user: AuthUser | null }; error: DbError | null }>;
    signOut(): Promise<{ error: DbError | null }>;
  };
  from(table: string): QueryBuilder;
}
