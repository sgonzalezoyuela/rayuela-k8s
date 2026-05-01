# Rayuela K8s — common tasks
# Run `just` to list available recipes

# List available recipes
default:
    @just --list

# ── Deployment ────────────────────────────────────────────────────────

# Deploy to dev environment
deploy-dev:
    kubectl apply -k env/dev

# Deploy to prod environment (runs a prod DB backup first)
deploy-prod:
    ./scripts/db/backup-prod.sh
    kubectl apply -k env/prod

# ── Database ──────────────────────────────────────────────────────────

# Connect harlequin (PostgreSQL TUI) to the dev DB via kubectl port-forward
ha-dev *args:
    ./scripts/db/ha.sh dev {{args}}

# Connect harlequin (PostgreSQL TUI) to the prod DB via kubectl port-forward
ha-prod *args:
    ./scripts/db/ha.sh prod {{args}}

# Create a local backup of the production database
backup-prod:
    ./scripts/db/backup-prod.sh

# ── Releases ──────────────────────────────────────────────────────────

# Bump Rayuela version for dev environment (e.g. `just release-bump-dev 0.6.0-dev`)
release-bump-dev version:
    ./scripts/release/bump-version.sh {{version}} dev

# Bump Rayuela version for prod environment (e.g. `just release-bump-prod 1.0.0-rc1`)
release-bump-prod version:
    ./scripts/release/bump-version.sh {{version}} prod

# Bump Rayuela version for all environments (e.g. `just release-bump-all 0.7.0`)
release-bump-all version:
    ./scripts/release/bump-version.sh {{version}} all
