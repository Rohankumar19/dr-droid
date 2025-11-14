# Deployment Guide

This guide walks you through deploying the microservices-demo project with monitoring and persistence.

## Prerequisites

1. **Kubernetes Cluster**: Choose one of the following:
   - **Minikube** (Local): `minikube start --cpus=4 --memory=8192`
   - **Kind** (Local): `kind create cluster --config kind-config.yaml`
   - **Cloud Provider**: GKE, EKS, AKS, or DigitalOcean Kubernetes
   - **Self-hosted**: K3s, Kubeadm, etc.

2. **Tools**:
   - kubectl (configured to access your cluster)
   - helm 3.x
   - git

## Quick Deployment

### Option 1: Automated Setup (Recommended)

**Linux/Mac:**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

**Windows:**
```powershell
.\scripts\setup.ps1
```

### Option 2: Manual Step-by-Step

#### 1. Create Namespaces
```bash
kubectl apply -f k8s/namespace.yaml
kubectl create namespace monitoring
```

#### 2. Deploy PostgreSQL (Bonus Feature)
```bash
kubectl apply -f k8s/postgres/postgres.yaml

# Wait for PostgreSQL
kubectl wait --for=condition=ready pod -l app=postgres -n microservices-demo --timeout=300s

# Verify database initialization
kubectl wait --for=condition=complete job/postgres-init -n microservices-demo --timeout=300s
```

#### 3. Deploy Microservices
```bash
kubectl apply -f k8s/microservices-demo/release.yaml
kubectl apply -f k8s/microservices-demo/orderservice-persistence.yaml

# Wait for services to be ready
kubectl wait --for=condition=ready pod -l app=frontend -n microservices-demo --timeout=300s
```

#### 4. Install Monitoring Stack

**Add Helm repos:**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

**Install Prometheus + Grafana:**
```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f monitoring/prometheus-values.yaml \
  --wait
```

**Install Loki:**
```bash
helm install loki grafana/loki-stack \
  -n monitoring \
  -f monitoring/loki-values.yaml \
  --wait
```

#### 5. Deploy Traffic Generator
```bash
kubectl apply -f k8s/traffic-generator/k6-configmap.yaml
kubectl apply -f k8s/traffic-generator/k6-job.yaml
```

## Accessing Services

### Grafana Dashboard
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
- URL: http://localhost:3000
- Username: `admin`
- Password: `prom-operator`

### Application Frontend
```bash
kubectl port-forward -n microservices-demo svc/frontend 8080:80
```
- URL: http://localhost:8080

### PostgreSQL Database
```bash
kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders
```

Example queries:
```sql
-- View all orders
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;

-- View order items
SELECT * FROM order_items LIMIT 10;

-- Order statistics
SELECT 
  COUNT(*) as total_orders,
  SUM(total_amount) as total_revenue,
  AVG(total_amount) as avg_order_value
FROM orders;
```

## Exposing Grafana Publicly (Bonus Interview Guarantee)

### Option 1: LoadBalancer (Cloud Provider)
```bash
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc prometheus-grafana -n monitoring
```

### Option 2: NodePort (Self-hosted)
```bash
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort"}}'
kubectl get svc prometheus-grafana -n monitoring
```
Access via: `http://<node-ip>:<node-port>`

### Option 3: Ingress (Recommended for Production)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
spec:
  rules:
  - host: grafana.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-grafana
            port:
              number: 80
```

## Verification Checklist

### 1. Application Metrics ✓
- [ ] Grafana accessible
- [ ] Prometheus data source connected
- [ ] Kubernetes cluster metrics visible
- [ ] Application pods metrics visible
- [ ] Request rates showing data

### 2. Application Logs ✓
- [ ] Loki data source connected
- [ ] Pod logs visible in Grafana
- [ ] Log filtering working
- [ ] Multiple services logging

### 3. Bonus: Persistence Layer ✓
- [ ] PostgreSQL running
- [ ] Database schema created
- [ ] Order persistence service running
- [ ] Can query orders table
- [ ] Order analytics dashboard configured

### 4. Traffic Generation ✓
- [ ] k6 jobs running
- [ ] Traffic visible in metrics
- [ ] Logs showing activity
- [ ] No error spikes

## Monitoring Commands

```bash
# Check all pods
kubectl get pods -n microservices-demo
kubectl get pods -n monitoring

# View logs
kubectl logs -n microservices-demo -l app=frontend --tail=50
kubectl logs -n microservices-demo -l app=order-persistence --tail=50
kubectl logs -n microservices-demo -l app=k6-load-test --tail=50

# Check traffic generator
kubectl get jobs -n microservices-demo
kubectl get cronjobs -n microservices-demo

# Database connection test
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "SELECT COUNT(*) FROM orders;"
```

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n microservices-demo
kubectl logs <pod-name> -n microservices-demo
```

### Grafana not accessible
```bash
kubectl get svc -n monitoring
kubectl describe svc prometheus-grafana -n monitoring
```

### Database connection issues
```bash
kubectl logs -n microservices-demo deployment/postgres
kubectl exec -it -n microservices-demo deployment/postgres -- pg_isready
```

### No metrics showing
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
kubectl get servicemonitors -n monitoring
```

## Cleanup

```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

Or manually:
```bash
helm uninstall loki -n monitoring
helm uninstall prometheus -n monitoring
kubectl delete namespace microservices-demo
kubectl delete namespace monitoring
```

## Submission Checklist

- [ ] Grafana accessible with public URL or credentials provided
- [ ] Dashboard showing Kubernetes metrics
- [ ] Dashboard showing application metrics
- [ ] Application logs visible in Grafana
- [ ] Traffic generator running and visible
- [ ] PostgreSQL deployed with order persistence
- [ ] Database schema created and queryable
- [ ] Repository forked with persistence modifications
- [ ] Email sent to siddarth@drdroid.io with:
  - Dashboard URL
  - Login credentials (or team access granted)
  - Repository link (if forked)
  - Brief description of setup

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Microservices Demo Namespace              │  │
│  │                                                    │  │
│  │  Frontend → Checkout → Product Catalog            │  │
│  │      ↓         ↓           ↓                       │  │
│  │   Cart    Payment    Recommendation               │  │
│  │      ↓         ↓           ↓                       │  │
│  │   Redis   Shipping    Currency                    │  │
│  │                                                    │  │
│  │  Order Persistence → PostgreSQL (Bonus)           │  │
│  │                                                    │  │
│  │  k6 Traffic Generator (CronJob)                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │           Monitoring Namespace                    │  │
│  │                                                    │  │
│  │  Prometheus ← Scrapes metrics from pods           │  │
│  │       ↓                                            │  │
│  │  Grafana ← Visualizes metrics & logs              │  │
│  │       ↑                                            │  │
│  │  Loki ← Collects logs via Promtail                │  │
│  └──────────────────────────────────────────────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```
