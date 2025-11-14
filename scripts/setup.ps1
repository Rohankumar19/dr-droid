# PowerShell setup script for Windows
$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Microservices Demo Setup Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "kubectl is required but not installed. Aborting." -ForegroundColor Red
    exit 1
}
if (!(Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "helm is required but not installed. Aborting." -ForegroundColor Red
    exit 1
}

# Add Helm repositories
Write-Host "Adding Helm repositories..." -ForegroundColor Yellow
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespaces
Write-Host "Creating namespaces..." -ForegroundColor Yellow
kubectl apply -f k8s/namespace.yaml
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy PostgreSQL (Bonus)
Write-Host "Deploying PostgreSQL..." -ForegroundColor Yellow
kubectl apply -f k8s/postgres/postgres.yaml
Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=postgres -n microservices-demo --timeout=300s

# Initialize database
Write-Host "Initializing database schema..." -ForegroundColor Yellow
kubectl wait --for=condition=complete job/postgres-init -n microservices-demo --timeout=300s

# Deploy microservices
Write-Host "Deploying microservices..." -ForegroundColor Yellow
kubectl apply -f k8s/microservices-demo/release.yaml
kubectl apply -f k8s/microservices-demo/orderservice-persistence.yaml

Write-Host "Waiting for microservices to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=frontend -n microservices-demo --timeout=300s

# Install Prometheus Stack
Write-Host "Installing Prometheus and Grafana..." -ForegroundColor Yellow
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
  -n monitoring `
  -f monitoring/prometheus-values.yaml `
  --wait

# Install Loki
Write-Host "Installing Loki..." -ForegroundColor Yellow
helm upgrade --install loki grafana/loki-stack `
  -n monitoring `
  -f monitoring/loki-values.yaml `
  --wait

# Deploy traffic generator
Write-Host "Deploying traffic generator..." -ForegroundColor Yellow
kubectl apply -f k8s/traffic-generator/k6-configmap.yaml
kubectl apply -f k8s/traffic-generator/k6-job.yaml

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access Grafana:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
Write-Host "  URL: http://localhost:3000"
Write-Host "  Username: admin"
Write-Host "  Password: prom-operator"
Write-Host ""
Write-Host "Access Application:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n microservices-demo svc/frontend 8080:80"
Write-Host "  URL: http://localhost:8080"
Write-Host ""
Write-Host "Check PostgreSQL:" -ForegroundColor Cyan
Write-Host "  kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders"
Write-Host ""
Write-Host "View logs:" -ForegroundColor Cyan
Write-Host "  kubectl logs -n microservices-demo -l app=frontend --tail=100"
Write-Host ""
Write-Host "Monitor traffic generation:" -ForegroundColor Cyan
Write-Host "  kubectl logs -n microservices-demo -l app=k6-load-test --tail=100"
Write-Host ""
