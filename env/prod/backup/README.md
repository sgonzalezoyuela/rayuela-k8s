# Rayuela Database Backup

Daily backup of PostgreSQL databases to restic REST server via nginx reverse proxy.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  K8s Cluster    │────▶│  nginx proxy    │────▶│  restic server  │
│  (backup job)   │     │  (10.0.3.2)     │     │  (cemcc-t)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              │
                              │ Tailscale
                              ▼
```

## Configuration

| Setting | Value |
|---------|-------|
| Schedule | Daily at 02:00 AM (Argentina time) |
| Databases | grexc, grext1, grext2 |
| Repository | `rest:http://10.0.3.2:8000/rayuela` (via nginx proxy) |
| Retention | 7 daily, 4 weekly, 12 monthly |

## Setup

### 1. Configure nginx proxy (on 10.0.3.2)

The nginx server proxies requests to the restic server via Tailscale:

```nginx
server {
    listen 8000;
    location / {
        proxy_pass http://cemcc-t:8000;
        proxy_connect_timeout 60s;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        client_max_body_size 0;
    }
}
```

### 2. Initialize restic repository (first time only)

From a machine with Tailscale access:
```bash
export RESTIC_REPOSITORY="rest:http://cemcc-t:8000/rayuela"
export RESTIC_PASSWORD="YOUR_RESTIC_PASSWORD"
restic init
```

### 3. Create the backup secret

```bash
./scripts/seal-backup-secret.sh
```

### 4. Deploy

```bash
kubectl apply -k env/prod
```

## Manual Operations

### Trigger backup manually

```bash
kubectl create job --from=cronjob/rayuela-db-backup rayuela-db-backup-manual -n rayuela
kubectl logs -f job/rayuela-db-backup-manual -n rayuela
```

### List snapshots

```bash
restic -r rest:http://cemcc-t:8000/rayuela snapshots
```

### Restore a database

```bash
# Restore latest snapshot to a local directory
restic -r rest:http://cemcc-t:8000/rayuela restore latest --target /tmp/restore

# Restore specific database
pg_restore -h <host> -U grex -d grexc /tmp/restore/tmp/backup/grexc.dump

# Or restore to a new database
createdb -h <host> -U grex grexc_restored
pg_restore -h <host> -U grex -d grexc_restored /tmp/restore/tmp/backup/grexc.dump
```

### Restore from specific snapshot

```bash
# List snapshots
restic -r rest:http://cemcc-t:8000/rayuela snapshots

# Restore specific snapshot
restic -r rest:http://cemcc-t:8000/rayuela restore abc123 --target /tmp/restore
```
