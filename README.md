# Rayuela Kubernetes Deployment

Kubernetes manifests for deploying Rayuela to dev and production environments.

## Directory Structure

```
rayuela-k8s/
├── infra/                    # Cluster infrastructure components
│   └── sealed-secrets/       # Sealed Secrets controller (v0.34.0)
├── base/                     # Shared application base
│   ├── database/             # PostgreSQL 17 StatefulSet
│   └── app/                  # Rayuela application + SQL seed data
├── env/
│   ├── dev/                  # Development environment (namespace: rayuela-dev)
│   │   ├── namespace.yaml
│   │   ├── sealed-secrets/   # Encrypted secrets for dev
│   │   └── patches/          # Dev-specific overrides
│   └── prod/                 # Production environment (namespace: rayuela-prod)
│       ├── namespace.yaml
│       ├── sealed-secrets/   # Encrypted secrets for prod
│       └── patches/          # Prod-specific overrides
└── scripts/
    ├── db/                   # Database operations
    │   ├── backup-prod.sh    # Create local backup from production
    │   ├── restore-dev.sh    # Restore backup into K8s dev
    │   ├── restore-local.sh  # Restore backup into local Docker
    │   ├── seed-dev.sh       # Seed development data
    │   ├── seed-prod.sh      # Seed production data
    │   ├── check-restic-backup-prod.sh  # Monitor automated backups
    │   └── backfill-legajo-defaults.sh  # One-time data migration
    ├── secrets/              # Secret management
    │   ├── seal-secret.sh    # Seal app secrets (dev/prod)
    │   └── seal-backup-secret.sh  # Seal backup secret (prod)
    └── release/              # Release management
        └── bump-version.sh   # Update version across env configs
```

## Prerequisites

- Kubernetes cluster (Talos Linux)
- `kubectl` configured to access the cluster
- `kubeseal` CLI installed
- Container image available at `ghcr.io/sgonzalezoyuela/rayuela:<tag>`

## Quick Start

### 1. Install Sealed Secrets Controller

```bash
kubectl apply -k infra/sealed-secrets
```

Wait for the controller to be ready:

```bash
kubectl rollout status deployment/sealed-secrets-controller -n kube-system
```

### 2. Seal Your Secrets

The script will prompt for database password and OIDC credentials (all required):

```bash
# For dev environment
./scripts/secrets/seal-secret.sh dev

# For prod environment
./scripts/secrets/seal-secret.sh prod
```

### 3. Deploy

```bash
# Deploy to dev
kubectl apply -k env/dev

# Deploy to prod
kubectl apply -k env/prod
```

### 4. Verify Deployment

```bash
# Check pods (use appropriate namespace)
kubectl get pods -n rayuela-dev   # dev
kubectl get pods -n rayuela       # prod

# Check services
kubectl get svc -n rayuela-dev    # dev
kubectl get svc -n rayuela        # prod

# View logs
kubectl logs -n rayuela-dev -l app.kubernetes.io/name=rayuela -f   # dev
kubectl logs -n rayuela -l app.kubernetes.io/name=rayuela -f       # prod
```

## Environments

| Environment | Namespace | Domain | Replicas | CPU | Memory | DB Storage |
|-------------|-----------|--------|----------|-----|--------|------------|
| dev | `rayuela-dev` | rayuela-dev.grex.com.ar | 1 | 250m-500m | 512Mi-1Gi | 5Gi |
| prod | `rayuela` | rayue.la| 2 | 500m-1000m | 1Gi-2Gi | 20Gi |

## Configuration

### Environment Variables

The application is configured via environment variables in ConfigMaps and Secrets.

#### Base Configuration (`base/app/configmap.yaml`)

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | Database host | `rayuela-db` |
| `DB_PORT` | Database port | `5432` |
| `DB_NAME` | Database name | `rayuela` |
| `DB_USERNAME` | Database username | `grex` |
| `DB_PASSWORD` | Database password (via Secret) | - |
| `SERVER_PORT` | Application port | `8080` |
| `TZ` | Timezone | `America/Argentina/Buenos_Aires` |

#### Environment-Specific Overrides

**Dev** (`env/dev/patches/configmap.yaml`):
| Variable | Value |
|----------|-------|
| `SPRING_PROFILES_ACTIVE` | `dev` |
| `RAYUELA_ENV` | `Desarrollo` |
| `LOGGING_LEVEL_COM_RAYUELA` | `DEBUG` |
| `OIDC_ISSUER_URI` | Dev Auth0 tenant |
| `RAYUELA_VERSION` | `0.6.0-dev` |

**Prod** (`env/prod/patches/configmap.yaml`):
| Variable | Value |
|----------|-------|
| `SPRING_PROFILES_ACTIVE` | `prod` |
| `RAYUELA_ENV` | `Produccion` |
| `LOGGING_LEVEL_COM_RAYUELA` | `INFO` |
| `OIDC_ISSUER_URI` | Production OIDC provider |
| `RAYUELA_VERSION` | `0.5.1` |

### Secrets (Sealed)

Secrets are stored encrypted in `env/*/sealed-secrets/secrets.yaml`:

| Key | Description | Required |
|-----|-------------|----------|
| `db-password` | PostgreSQL password | **Yes** |
| `oidc-client-id` | OAuth2/OIDC client ID | **Yes** |
| `oidc-client-secret` | OAuth2/OIDC client secret | **Yes** |

**Important:** All secrets are required. The application will fail to start without valid OIDC credentials.

### OAuth2/OIDC Configuration

The application requires OIDC authentication. Configure before deployment:

1. **Get Auth0 credentials:**
   - Log in to Auth0 Dashboard
   - Create or select your Application (Regular Web Application)
   - Copy Client ID and Client Secret

2. **Configure callback URLs in Auth0:**
   | Environment | Callback URL | Logout URL |
   |-------------|--------------|------------|
   | Dev | `https://rayuela-dev.grex.com.ar/login/oauth2/code/oidc` | `https://rayuela-dev.grex.com.ar/` |
   | Prod | `https://rayue.la/login/oauth2/code/oidc` | `https://rayue.la/` |

3. **Update OIDC issuer URI** in `env/<env>/patches/configmap.yaml`:
   ```yaml
   OIDC_ISSUER_URI: "https://rayuela.us.auth0.com/"
   ```

4. **Seal the secrets** with OIDC credentials:
   ```bash
   ./scripts/secrets/seal-secret.sh dev
   # Enter database password, OIDC Client ID, and OIDC Client Secret
   ```

5. **Deploy:**
   ```bash
   kubectl apply -k env/dev
   ```

## Version Management

Versions are managed per-environment. Each environment has:
- `RAYUELA_VERSION` in `env/<env>/patches/configmap.yaml` (app metadata)
- `newTag` in `env/<env>/kustomization.yaml` (container image tag)

### Bumping a Version

Use the release script to update both files atomically:

```bash
# Bump dev to a new version
./scripts/release/bump-version.sh 0.7.0-dev dev

# Bump prod to a release version
./scripts/release/bump-version.sh 0.6.0 prod

# Bump both environments at once
./scripts/release/bump-version.sh 1.0.0 all
```

Then deploy:

```bash
kubectl apply -k env/dev   # or env/prod
```

## Sealed Secrets

Secrets are encrypted using Bitnami Sealed Secrets. The encrypted secrets in `env/*/sealed-secrets/` are safe to commit to Git.

### How It Works

1. `kubeseal` encrypts secrets using the cluster's public key
2. Only the Sealed Secrets controller in that cluster can decrypt them
3. Controller creates regular Kubernetes Secrets from SealedSecrets

### Rotating Secrets

```bash
# Generate new sealed secret (will prompt for all values)
./scripts/secrets/seal-secret.sh dev

# Commit and apply
git add env/dev/sealed-secrets/secrets.yaml
git commit -m "chore: rotate dev secrets"
kubectl apply -k env/dev

# Restart pods to pick up new secret
kubectl rollout restart deployment/rayuela -n rayuela
kubectl rollout restart statefulset/rayuela-db -n rayuela
```

## Database

PostgreSQL 17 runs as a StatefulSet with persistent storage.

### Database Architecture (Schema-Per-Tenant)

Rayuela uses a **single PostgreSQL database** (`rayuela`) with schema-based multi-tenancy:

- **`public` schema** — Central/shared data: organizations, users, user_org_assignments, convenios, cargos, conceptos, concepto_versiones, obras_sociales
- **`tenant_{uuid}` schemas** — Per-organization data: business_units, tenant_users, roles, permissions, legajos, liquidaciones

Tenant schemas are created automatically by the init container and at runtime by the application when new organizations are provisioned via the API.

### Database Initialization

An **init container** runs before the Rayuela application starts. It:

1. Waits for PostgreSQL to be ready (up to 30 retries)
2. Grants privileges on the `public` schema and `CREATE ON DATABASE` to the app user
3. Creates tenant schemas from the `TENANT_SCHEMAS` env var (comma-separated UUIDs set per-environment via Kustomize patches)
4. Grants full privileges on each tenant schema

After the init container completes, Flyway runs migrations on `public` and all `tenant_*` schemas when the app starts.

The init container uses PostgreSQL 17 Alpine image and runs `base/app/init-db.sh`.

### SQL Seed Data

Seed data files are located in `env/{dev,prod}/sql/`. Each file sets its own `search_path` to target the correct schema.

| File | Schema | Contents |
|------|--------|----------|
| `central-data.sql` | `public` | Organizations, users, user-org assignments |
| `convenios-data.sql` | `public` | Salary agreements |
| `cargos-data.sql` | `public` | Job titles |
| `conceptos-data.sql` | `public` | Payroll concepts |
| `concepto-versiones-data.sql` | `public` | Temporal concept configuration |
| `tenant1-data.sql` | `tenant_{uuid}` | Business units, users, roles for tenant 1 |
| `tenant2-data.sql` | `tenant_{uuid}` | Business units, users, roles for tenant 2 |

Seed data must be loaded **manually** after deployment (Flyway creates the tables first):

```bash
# Production
scripts/db/seed-prod.sh

# Development
scripts/db/seed-dev.sh
```

All SQL uses `ON CONFLICT DO UPDATE` for idempotency — safe to run multiple times.

### Checking Init Container Logs

```bash
# View init container logs
kubectl logs -n rayuela deployment/rayuela -c init-db

# If pod is still initializing
kubectl logs -n rayuela <pod-name> -c init-db
```

### Connecting to Database

```bash
# Port-forward to local machine
kubectl port-forward -n rayuela svc/rayuela-db 5432:5432

# Connect with psql
psql -h localhost -U grex -d rayuela
```

## Pangolin Integration

The application is exposed via ClusterIP service on port 8080. Configure Pangolin to route:

| Domain | Target |
|--------|--------|
| rayuela-dev.grex.com.ar | rayuela.rayuela.svc.cluster.local:8080 |
| rayue.la | rayuela.rayuela.svc.cluster.local:8080 |

## Troubleshooting

### Check Application Logs

```bash
kubectl logs -n rayuela -l app.kubernetes.io/name=rayuela --tail=100 -f
```

### Check Database Logs

```bash
kubectl logs -n rayuela -l app.kubernetes.io/name=rayuela-db --tail=100 -f
```

### Check Events

```bash
kubectl get events -n rayuela --sort-by='.lastTimestamp'
```

### Describe Resources

```bash
kubectl describe deployment/rayuela -n rayuela
kubectl describe statefulset/rayuela-db -n rayuela
```

### Database Init Issues

If databases aren't created, check the init script:

```bash
kubectl logs -n rayuela rayuela-db-0 -c postgres | head -50
```

### OIDC Issues

Check security debug logs:

```bash
kubectl logs -n rayuela -l app.kubernetes.io/name=rayuela --tail=200 | grep -i security
```

Verify OIDC config:

```bash
kubectl get configmap rayuela-config -n rayuela -o yaml | grep OIDC
kubectl get secret rayuela-secrets -n rayuela -o jsonpath='{.data.oidc-client-id}' | base64 -d
```

## Kustomize Build Preview

To see the full rendered manifests without applying:

```bash
# Dev
kubectl kustomize env/dev

# Prod
kubectl kustomize env/prod
```
