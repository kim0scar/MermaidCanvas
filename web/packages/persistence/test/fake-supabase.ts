import type {
  AuthUser,
  DbError,
  DbResult,
  QueryBuilder,
  Row,
  SupabaseLikeClient,
} from '../src/index.js';

// Stateful mock av SupabaseLikeClient — beter sig som en mini-PostgREST i minnet
// och loggar varje exekverat anrop så testerna kan verifiera tabell/kolumner/filter.

export interface LoggedCall {
  table: string;
  op: 'select' | 'insert' | 'update' | 'delete';
  columns: string | undefined;
  values: Row | undefined;
  eq: Array<[string, unknown]>;
  single: boolean;
}

let nextId = 1;

function defaultsFor(table: string): Row {
  if (table === 'files') {
    return { id: `fil-${nextId++}`, updated_at: new Date().toISOString() };
  }
  return {};
}

export class FakeSupabase implements SupabaseLikeClient {
  readonly tables: Record<string, Row[]> = { files: [], shares: [] };
  user: AuthUser | null = null;
  readonly calls: LoggedCall[] = [];
  private nextError: DbError | null = null;

  /** Nästa exekverade anrop (query ELLER signInWithOtp) misslyckas med detta meddelande. */
  failNextWith(message: string): void {
    this.nextError = { message };
  }

  takeError(): DbError | null {
    const e = this.nextError;
    this.nextError = null;
    return e;
  }

  auth = {
    signInWithOtp: async ({ email }: { email: string }) => {
      const error = this.takeError();
      if (error) return { error };
      this.user = { id: `user-${email}`, email };
      return { error: null };
    },
    getUser: async () => ({ data: { user: this.user }, error: null }),
    signOut: async () => {
      this.user = null;
      return { error: null };
    },
  };

  from(table: string): QueryBuilder {
    return new FakeBuilder(this, table);
  }
}

class FakeBuilder implements QueryBuilder {
  private op: LoggedCall['op'] = 'select';
  private columns: string | undefined;
  private values: Row | undefined;
  private readonly eqs: Array<[string, unknown]> = [];

  constructor(
    private readonly db: FakeSupabase,
    private readonly table: string,
  ) {}

  select(columns?: string): QueryBuilder {
    this.columns = columns;
    return this;
  }

  insert(row: Row): QueryBuilder {
    this.op = 'insert';
    this.values = row;
    return this;
  }

  update(patch: Row): QueryBuilder {
    this.op = 'update';
    this.values = patch;
    return this;
  }

  delete(): QueryBuilder {
    this.op = 'delete';
    return this;
  }

  eq(column: string, value: unknown): QueryBuilder {
    this.eqs.push([column, value]);
    return this;
  }

  private rows(): Row[] {
    return (this.db.tables[this.table] ??= []);
  }

  private matches(row: Row): boolean {
    return this.eqs.every(([col, val]) => row[col] === val);
  }

  private project(row: Row): Row {
    if (!this.columns || this.columns === '*') return { ...row };
    const out: Row = {};
    for (const raw of this.columns.split(',')) {
      const col = raw.trim();
      out[col] = row[col];
    }
    return out;
  }

  private run(single: boolean): DbResult<Row[]> {
    this.db.calls.push({
      table: this.table,
      op: this.op,
      columns: this.columns,
      values: this.values,
      eq: [...this.eqs],
      single,
    });
    const injected = this.db.takeError();
    if (injected) return { data: null, error: injected };

    if (this.op === 'insert') {
      const row: Row = { ...defaultsFor(this.table), ...this.values };
      this.rows().push(row);
      return { data: [this.project(row)], error: null };
    }
    if (this.op === 'update') {
      const hit = this.rows().filter((r) => this.matches(r));
      for (const r of hit) Object.assign(r, this.values);
      return { data: hit.map((r) => this.project(r)), error: null };
    }
    if (this.op === 'delete') {
      this.db.tables[this.table] = this.rows().filter((r) => !this.matches(r));
      return { data: null, error: null };
    }
    return {
      data: this.rows()
        .filter((r) => this.matches(r))
        .map((r) => this.project(r)),
      error: null,
    };
  }

  then<TResult1 = DbResult<Row[]>, TResult2 = never>(
    onfulfilled?: ((value: DbResult<Row[]>) => TResult1 | PromiseLike<TResult1>) | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): PromiseLike<TResult1 | TResult2> {
    return Promise.resolve(this.run(false)).then(onfulfilled, onrejected);
  }

  single(): PromiseLike<DbResult<Row>> {
    const res = this.run(true);
    if (res.error) return Promise.resolve({ data: null, error: res.error });
    const rows = res.data ?? [];
    const first = rows[0];
    if (rows.length === 1 && first !== undefined) {
      return Promise.resolve({ data: first, error: null });
    }
    return Promise.resolve({
      data: null,
      error: { message: `single() förväntade 1 rad, fick ${rows.length}`, code: 'PGRST116' },
    });
  }
}
