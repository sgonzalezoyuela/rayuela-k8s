# Ad-hoc SQL queries

Stand-alone `.sql` files for poking at the rayuela database from a Postgres
client (harlequin, psql, DataGrip, …). Conventions used in every file in
this directory:

| Convention | Why |
| --- | --- |
| **No psql meta-commands** (`\set`, `\gexec`, …) | So the file works in any client, including the `harlequin` TUI launched by `scripts/db/ha.sh`. |
| **Placeholders live in a leading `WITH params AS (…)` CTE** | One obvious place to edit before running — no scattered ids. |
| **Public-schema tables are schema-qualified** (`public.cargos`) | The file works whether or not you've set `search_path` to a tenant. |
| **Tenant-scoped files document `SET search_path` at the top** | Tenant data lives in `tenant_<uuid>` schemas; you pick which one before running. |

## Files

| File | Scope | Placeholder to edit |
| --- | --- | --- |
| `list-legajos.sql` | Tenant (set `search_path`) | — |
| `list-detalles-for-liquidacion.sql` | Tenant (set `search_path`) | `liquidacion_id` UUID |
| `list-conceptos-for-convenio.sql` | Public (no tenant needed) | `convenio_codigo` |

## Running them

Inside the project's Nix shell (`nix develop` or `direnv allow`):

### From harlequin

```bash
just ha-prod                 # or: just ha-dev
```

In the query editor:

```sql
-- tenant-scoped queries: set search_path once per session
SET search_path TO "tenant_f780d30d-20a4-4d0a-a2f7-b3a1523eb3d6", public;

-- then paste the contents of list-legajos.sql (or any other file)
```

### From psql

```bash
kubectl port-forward -n rayuela-prod svc/rayuela-db 5432:5432

# Tenant-scoped: pass the SET via -c so it shares the session with -f
psql -h localhost -U grex -d rayuela \
     -c 'SET search_path TO "tenant_<uuid>", public;' \
     -f scripts/db/sql/list-legajos.sql

# Public-only: no SET needed
psql -h localhost -U grex -d rayuela \
     -f scripts/db/sql/list-conceptos-for-convenio.sql
```

## Adding a new query

1. Drop a new `.sql` file in this directory.
2. Put a header comment that names the file, summarises what it returns, and
   spells out any required `SET search_path` and placeholders.
3. If the query takes parameters, put them in a leading `WITH params AS (…)`
   CTE so there's exactly one place to edit before running.
4. Schema-qualify any reference to `public.*` tables.
5. Add a row to the table above.
