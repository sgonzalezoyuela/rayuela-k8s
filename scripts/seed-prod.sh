#!/usr/bin/env bash

# Seed central database
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grexc -f /sql/central-data.sql
# Seed tenant 1 database
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext1 -f /sql/convenios-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext1 -f /sql/cargos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext1 -f /sql/conceptos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext1 -f /sql/concepto-versiones-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext1 -f /sql/tenant1-data.sql
# Migrations (tenant 1)
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext1 -f /sql/001-add-stella-maris-bu.sql
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext1 -f /sql/002-add-convenio-escala-salarial.sql
# Seed tenant 2 database (if needed)
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext2 -f /sql/convenios-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext2 -f /sql/cargos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext2 -f /sql/conceptos-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext2 -f /sql/concepto-versiones-data.sql
kubectl exec -it rayuela-db-0 -n rayuela-prod -- psql -U grex -d grext2 -f /sql/tenant2-data.sql
