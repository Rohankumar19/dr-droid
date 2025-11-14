#!/bin/bash
set -e

echo "========================================="
echo "Microservices Demo Setup Script"
echo "========================================="

# Check prerequisites
echo "Checking prerequisites..."
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm is required but not installed. Aborting." >&2; exit 1; }

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespaces
echo "Creating namespaces..."
kubectl apply -f k8s/namespace.yaml
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy PostgreSQL (Bonus)
echo "Deploying PostgreSQL..."
kubectl apply -f k8s/postgres/postgres.yaml
echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n microservices-demo --timeout=300s

# Initialize database
echo "Initializing database schema..."
kubectl wait --for=condition=complete job/postgres-init -n microservices-demo --timeout=300s

# Deploy microservices
echo "Deploying microservices..."
kubectl apply -f k8s/microservices-demo/release.yaml
kubectl apply -f k8s/microservices-demo/orderservice-persistence.yaml

echo "Waiting for microservices to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n microservices-demo --timeout=300s

# Install Prometheus Stack
echo "Installing Prometheus and Grafana..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f monitoring/prometheus-values.yaml \
  --wait

# Install Loki
echo "Installing Loki..."
helm upgrade --install loki grafana/loki-stack \
  -n monitoring \
  -f monitoring/loki-values.yaml \
  --wait

# Deploy traffic generator
echo "Deploying traffic generator..."
kubectl apply -f k8s/traffic-generator/k6-configmap.yaml
kubectl apply -f k8s/traffic-generator/k6-job.yaml

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  URL: http://localhost:3000"
echo "  Username: admin"
echo "  Password: prom-operator"
echo ""
echo "Access Application:"
echo "  kubectl port-forward -n microservices-demo svc/frontend 8080:80"
echo "  URL: http://localhost:8080"
echo ""
echo "Check PostgreSQL:"
echo "  kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders"
echo ""
echo "View logs:"
echo "  kubectl logs -n microservices-demo -l app=frontend --tail=100"
echo ""
echo "Monitor traffic generation:"
echo "  kubectl logs -n microservices-demo -l app=k6-load-test --tail=100"
echo ""
