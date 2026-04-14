# Rayuela K8s — common tasks
# Run `just` to list available recipes

# List available recipes
default:
    @just --list

# Deploy to dev environment
deploy-dev:
    kubectl apply -k env/dev

# Deploy to prod environment
deploy-prod:
    kubectl apply -k env/prod

# Create a local backup of the production database
backup-prod:
    ./scripts/db/backup-prod.sh