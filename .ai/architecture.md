# Rayuela K8s - Module Architecture

## Overview

Kubernetes deployment manifests for **Rayuela**, a multi-tenant payroll/HR management system for Argentine educational institutions. This repo contains Kustomize overlays for dev and prod environments.

## Technology Stack

- **Orchestration:** Kubernetes (bare-metal, single-node)
- **Configuration Management:** Kustomize (base + overlay pattern)
- **Database:** PostgreSQL 17 (Alpine)
- **Secrets Management:** Bitnami Sealed Secrets
- **Backup:** Restic via CronJob
- **Container Registry:** GitHub Container Registry (ghcr.io)

## Architecture

### Multi-Tenancy Model (Schema-Per-Tenant)

The application uses a **single PostgreSQL database** (`rayuela`) with schema-based multi-tenancy:

- `public` schema: central/system tables (organizations, users, user_org_assignments) + shared catalogs (convenios, cargos, conceptos, concepto_versiones, obras_sociales)
- `tenant_{org_uuid}` schemas: per-organization data (business_units, tenant_users, roles, permissions, legajos, liquidaciones)

Tenant schemas are created automatically by the application when a new organization is provisioned via the API. The init container pre-creates schemas for organizations that will be seeded via SQL.

### Kustomize Structure

```
base/                    # Shared resources (all environments)
  app/                   # Deployment, Service, ConfigMap, init-db.sh
  database/              # StatefulSet, Service, StorageClass
env/
  dev/                   # Dev overlay (rayuela-dev namespace)
    patches/             # Environment-specific patches
    sealed-secrets/      # Dev SealedSecrets
    sql/                 # Dev seed data
  prod/                  # Prod overlay (rayuela-prod namespace)
    patches/             # Environment-specific patches
    sealed-secrets/      # Prod SealedSecrets
    sql/                 # Prod seed data
    backup/              # CronJob for database backups
scripts/                 # Helper scripts (seal secrets, seed data)
infra/                   # Cluster infrastructure (sealed-secrets controller)
```

### Database Initialization Flow

1. **StatefulSet starts** → PostgreSQL creates `rayuela` database (via `POSTGRES_DB`)
2. **Init container runs** (`init-db.sh`) → Creates tenant schemas, grants privileges
3. **App starts** → Flyway runs migrations on `public` + all `tenant_*` schemas
4. **Manual step** → Operator runs `scripts/seed-{env}.sh` to load seed data

### Environment Variables

The Spring Boot application expects:
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` — single datasource
- `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_ISSUER_URI` — OAuth2/OIDC

### SQL Seed Data

Seed SQL files use `SET search_path` to target the correct schema:
- Public schema data: `SET search_path = 'public';`
- Tenant data: `SET search_path = 'tenant_{uuid}';`

All seed files are idempotent (ON CONFLICT DO UPDATE/NOTHING).

## Conventions

- **Naming:** K8s resources prefixed with `rayuela-` (e.g., `rayuela-db`, `rayuela-config`, `rayuela-secrets`)
- **Namespaces:** `rayuela-dev` (dev), `rayuela-prod` (prod)
- **Labels:** Standard `app.kubernetes.io/*` labels on all resources
- **Secrets:** Always via SealedSecrets, never plain Secrets in git. Sealed per-namespace.
- **Storage:** `rayuela-storage` StorageClass using `rancher.io/local-path`
- **SQL UUIDs:** Deterministic UUIDs for reproducibility (e.g., `00000000-0000-4000-8000-{codigo}`)

## Guidelines

- Keep base generic; all environment-specific config goes in overlays
- SQL seed files must be idempotent — safe to re-run
- Never commit plain secrets; use `scripts/seal-secret.sh` and `scripts/seal-backup-secret.sh`
- Init container should be environment-agnostic; tenant schema lists come from env-specific patches
- Backup covers the single `rayuela` database (all schemas included in pg_dump)
