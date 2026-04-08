# Feature: db.connection — Fix DB Connection

## Problem
The Spring Boot app expects env vars `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`.
The K8s ConfigMap provides `CENTRAL_DB_HOST`, `CENTRAL_DB_PORT`, etc. — which the app ignores,
falling back to hardcoded defaults (`localhost:5432/rayuela`).

## Verified Env Var Mapping

From `../rayuela/app/src/main/resources/application.yml` (lines 16-18):
```yaml
spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:rayuela}?sslmode=disable
    username: ${DB_USERNAME:grex}
    password: ${DB_PASSWORD:8dKv90)xv9Th}
```

## Changes

### 1. base/app/configmap.yaml
Replace lines 13-43 (all CENTRAL_DB_* and TENANT_T*_* entries) with:
```yaml
  # Database Configuration (single database, schema-per-tenant)
  DB_HOST: "rayuela-db"
  DB_PORT: "5432"
  DB_NAME: "rayuela"
  DB_USERNAME: "grex"
```
Remove: `CENTRAL_DB_HOST`, `CENTRAL_DB_PORT`, `CENTRAL_DB_NAME`, `CENTRAL_DB_USERNAME`,
`CENTRAL_DB_USE_TLS`, `TENANT_T1_NAME`, `TENANT_T1_DB_HOST`, `TENANT_T1_DB_PORT`,
`TENANT_T1_DB_USERNAME`, `TENANT_T1_DB_USE_TLS`, `TENANT_T2_NAME`, `TENANT_T2_DB_HOST`,
`TENANT_T2_DB_PORT`, `TENANT_T2_DB_USERNAME`, `TENANT_T2_DB_USE_TLS`

### 2. base/app/deployment.yaml
Init container (lines 44-48): rename `CENTRAL_DB_PASSWORD` → `DB_PASSWORD`
Main container (lines 82-96): rename `CENTRAL_DB_PASSWORD` → `DB_PASSWORD`,
remove `TENANT_T1_DB_PASSWORD` and `TENANT_T2_DB_PASSWORD` env entries entirely.

### 3. base/database/statefulset.yaml
- Line 42-43: Change `POSTGRES_DB` value from `postgres` to `rayuela`
- Line 41: Update comment to reflect single-database architecture
- Lines 66-68: Change health probe `-d postgres` to `-d rayuela`
- Lines 78-80: Change readiness probe `-d postgres` to `-d rayuela`

## Acceptance Criteria

1. base/app/configmap.yaml uses DB_HOST, DB_PORT, DB_NAME, DB_USERNAME instead of CENTRAL_DB_* and TENANT_T*_* vars
2. base/app/deployment.yaml uses DB_PASSWORD instead of CENTRAL_DB_PASSWORD for both init container and main container
3. base/app/deployment.yaml no longer references TENANT_T1_DB_PASSWORD or TENANT_T2_DB_PASSWORD
4. base/database/statefulset.yaml sets POSTGRES_DB to 'rayuela' instead of 'postgres'
5. base/database/statefulset.yaml health probes check against 'rayuela' database
6. env/prod/patches/configmap.yaml does not reference any CENTRAL_DB_* or TENANT_T*_* vars
