# Rayuela Kubernetes Deployment

Kubernetes manifests for deploying Rayuela to dev and production environments.

## Directory Structure

```
rayuela-k8s/
├── infra/                    # Cluster infrastructure components
│   └── sealed-secrets/       # Sealed Secrets controller (v0.34.0)
├── base/                     # Shared application base
│   ├── namespace.yaml
│   ├── database/             # PostgreSQL 17 StatefulSet
│   └── app/                  # Rayuela application
├── env/
│   ├── dev/                  # Development environment
│   │   ├── sealed-secrets/   # Encrypted secrets for dev
│   │   └── patches/          # Dev-specific overrides
│   └── prod/                 # Production environment
│       ├── sealed-secrets/   # Encrypted secrets for prod
│       └── patches/          # Prod-specific overrides
└── scripts/
    └── seal-secret.sh        # Helper to seal secrets
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

The script will prompt for database password and optional OIDC credentials:

```bash
# For dev environment
./scripts/seal-secret.sh dev

# For prod environment  
./scripts/seal-secret.sh prod
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
# Check pods
kubectl get pods -n rayuela

# Check services
kubectl get svc -n rayuela

# View logs
kubectl logs -n rayuela -l app.kubernetes.io/name=rayuela -f
```

## Environments

| Environment | Domain | Replicas | CPU | Memory | DB Storage |
|-------------|--------|----------|-----|--------|------------|
| dev | rayuela-dev.grex.com.ar | 1 | 250m-500m | 512Mi-1Gi | 5Gi |
| prod | rayuela.grex.com.ar | 2 | 500m-1000m | 1Gi-2Gi | 20Gi |

## Configuration

### Environment Variables

The application is configured via environment variables in ConfigMaps and Secrets.

#### Base Configuration (`base/app/configmap.yaml`)

| Variable | Description | Default |
|----------|-------------|---------|
| `CENTRAL_DB_HOST` | Central database host | `rayuela-db` |
| `CENTRAL_DB_PORT` | Central database port | `5432` |
| `CENTRAL_DB_NAME` | Central database name | `grexc` |
| `CENTRAL_DB_USERNAME` | Database username | `grex` |
| `TENANT_T1_*` | Tenant 1 database config | Same host, `grext1` |
| `TENANT_T2_*` | Tenant 2 database config | Same host, `grext2` |
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

**Prod** (`env/prod/patches/configmap.yaml`):
| Variable | Value |
|----------|-------|
| `SPRING_PROFILES_ACTIVE` | `prod` |
| `RAYUELA_ENV` | `Produccion` |
| `LOGGING_LEVEL_COM_RAYUELA` | `INFO` |
| `OIDC_ISSUER_URI` | Production OIDC provider |

### Secrets (Sealed)

Secrets are stored encrypted in `env/*/sealed-secrets/secrets.yaml`:

| Key | Description | Required |
|-----|-------------|----------|
| `db-password` | PostgreSQL password | Yes |
| `oidc-client-id` | OAuth2/OIDC client ID | No |
| `oidc-client-secret` | OAuth2/OIDC client secret | No |

### OAuth2/OIDC Configuration

To enable OAuth2/OIDC authentication:

1. Update `env/<env>/patches/configmap.yaml` with your OIDC issuer:
   ```yaml
   OIDC_ISSUER_URI: "https://your-provider.com/"
   ```

2. Run the seal script and provide OIDC credentials:
   ```bash
   ./scripts/seal-secret.sh dev
   # Enter OIDC Client ID and Secret when prompted
   ```

3. Configure your OIDC provider with callback URL:
   - Dev: `https://rayuela-dev.grex.com.ar/login/oauth2/code/oidc`
   - Prod: `https://rayuela.grex.com.ar/login/oauth2/code/oidc`

## Updating the Image

### Development

Edit `env/dev/patches/app-image.yaml`:

```yaml
image: ghcr.io/sgonzalezoyuela/rayuela:dev
imagePullPolicy: Always
```

Then apply:

```bash
kubectl apply -k env/dev
kubectl rollout restart deployment/rayuela -n rayuela
```

### Production

Edit `env/prod/patches/app-image.yaml` with the specific version:

```yaml
image: ghcr.io/sgonzalezoyuela/rayuela:1.0.0
imagePullPolicy: IfNotPresent
```

Then apply:

```bash
kubectl apply -k env/prod
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
./scripts/seal-secret.sh dev

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

### Databases Created

- `grexc` - Central database (organizations, users)
- `grext1` - Tenant 1 database
- `grext2` - Tenant 2 database

### Connecting to Database

```bash
# Port-forward to local machine
kubectl port-forward -n rayuela svc/rayuela-db 5432:5432

# Connect with psql
psql -h localhost -U grex -d grexc
```

## Pangolin Integration

The application is exposed via ClusterIP service on port 8080. Configure Pangolin to route:

| Domain | Target |
|--------|--------|
| rayuela-dev.grex.com.ar | rayuela.rayuela.svc.cluster.local:8080 |
| rayuela.grex.com.ar | rayuela.rayuela.svc.cluster.local:8080 |

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
