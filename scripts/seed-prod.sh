#!/usr/bin/env bash

# Seed central database
kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grexc -f /sql/central-data.sql
# Seed tenant 1 database
kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grext1 -f /sql/cargos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grext1 -f /sql/conceptos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grext1 -f /sql/tenant1-data.sql
# Seed tenant 2 database (if needed)
kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grext2 -f /sql/cargos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grext2 -f /sql/conceptos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela -- psql -U grex -d grext2 -f /sql/tenant2-data.sql
