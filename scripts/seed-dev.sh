#!/usr/bin/env bash

# Seed dev central database
kubectl exec -it rayuela-db-0 -n rayuela-dev -- psql -U grex -d grexc -f /sql/central-data.sql
# Seed dev tenant 1 database
kubectl exec -it rayuela-db-0 -n rayuela-dev -- psql -U grex -d grext1 -f /sql/cargos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-dev -- psql -U grex -d grext1 -f /sql/conceptos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-dev -- psql -U grex -d grext1 -f /sql/tenant1-data.sql
# Seed dev tenant 2 database (if needed)
kubectl exec -it rayuela-db-0 -n rayuela-dev -- psql -U grex -d grext2 -f /sql/cargos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-dev -- psql -U grex -d grext2 -f /sql/conceptos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-dev -- psql -U grex -d grext2 -f /sql/tenant2-data.sql
