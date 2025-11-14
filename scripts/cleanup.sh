#!/bin/bash
set -e

echo "Cleaning up microservices demo..."

# Delete traffic generator
kubectl delete -f k8s/traffic-generator/k6-job.yaml --ignore-not-found=true
kubectl delete -f k8s/traffic-generator/k6-configmap.yaml --ignore-not-found=true

# Delete microservices
kubectl delete -f k8s/microservices-demo/orderservice-persistence.yaml --ignore-not-found=true
kubectl delete -f k8s/microservices-demo/release.yaml --ignore-not-found=true

# Delete PostgreSQL
kubectl delete -f k8s/postgres/postgres.yaml --ignore-not-found=true

# Uninstall Helm releases
helm uninstall loki -n monitoring --ignore-not-found
helm uninstall prometheus -n monitoring --ignore-not-found

# Delete namespaces
kubectl delete namespace microservices-demo --ignore-not-found=true
kubectl delete namespace monitoring --ignore-not-found=true

echo "Cleanup complete!"
