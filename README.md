# Microservices Demo - Kubernetes Deployment with Monitoring

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)](https://grafana.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)

A complete implementation of Google's microservices-demo (Online Boutique) deployed on Kubernetes with comprehensive monitoring, logging, automated traffic generation, and a bonus persistence layer for order analytics.

**🎯 Created for**: DrDroid SRE/DevOps Position Assignment  
**⏱️ Deploy Time**: 5-10 minutes (fully automated)  
**📊 Features**: Metrics, Logs, Persistence, Analytics

## 🌟 Features

### ✅ Core Requirements
- **Microservices Deployment**: 10 services from Google's microservices-demo
- **Metrics Visualization**: Prometheus + Grafana with pre-configured dashboards
- **Log Aggregation**: Loki + Promtail with Grafana integration
- **Traffic Generation**: k6 load testing with realistic user behavior

### 🎁 Bonus Features
- **Persistence Layer**: PostgreSQL database for order data
- **Order Analytics**: Custom Grafana dashboard for business insights
- **Multi-Platform**: Scripts for Linux, Mac, and Windows
- **Cloud Ready**: Deployment guides for GKE, EKS, AKS, and more

## 🏗️ Architecture

- **Application**: Google microservices-demo (Online Boutique)
- **Orchestration**: Kubernetes
- **Metrics**: Prometheus + Grafana
- **Logs**: Loki + Promtail + Grafana
- **Traffic Generation**: k6 (CronJob every 15 minutes)
- **Persistence**: PostgreSQL for order data (Bonus feature)

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- helm 3.x installed

**New to Kubernetes?** Check out [GETTING_STARTED.md](GETTING_STARTED.md) for a complete beginner's guide.

### One-Command Deployment

**Linux/Mac:**
```bash
chmod +x scripts/setup.sh && ./scripts/setup.sh
```

**Windows:**
```powershell
.\scripts\setup.ps1
```

That's it! The script will:
1. ✅ Deploy all 10 microservices
2. ✅ Install Prometheus + Grafana
3. ✅ Install Loki for logs
4. ✅ Deploy PostgreSQL database
5. ✅ Start traffic generator
6. ✅ Configure dashboards

**Time**: 5-10 minutes

### Access Services

**Grafana (Monitoring):**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
- URL: http://localhost:3000
- Username: `admin`
- Password: `prom-operator`

**Application (Shop):**
```bash
kubectl port-forward -n microservices-demo svc/frontend 8080:80
```
- URL: http://localhost:8080

**PostgreSQL (Database):**
```bash
kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders
```

## ✅ Verify Installation

After deployment, verify everything is working:

**Linux/Mac:**
```bash
chmod +x scripts/verify.sh && ./scripts/verify.sh
```

**Windows:**
```powershell
.\scripts\verify.ps1
```

**Manual checks:**
```bash
# Check all pods are running
kubectl get pods -n microservices-demo
kubectl get pods -n monitoring

# Check services
kubectl get svc -n microservices-demo
kubectl get svc -n monitoring
```

**📖 Detailed Testing**: See [TESTING_GUIDE.md](TESTING_GUIDE.md) for comprehensive verification steps.

## 📊 Dashboards

Once Grafana is running, you'll have access to:

1. **Kubernetes Cluster Monitoring** - Node resources, pod status, cluster health
2. **Kubernetes Pods** - Per-pod metrics, container resources
3. **Node Exporter** - Detailed system metrics
4. **Application Metrics** - Request rates, errors, latency
5. **Order Analytics** (Bonus) - Revenue, orders, product insights

**Logs**: Use Grafana Explore with Loki data source to view and filter logs from all services.

## Project Structure

```
.
├── k8s/
│   ├── namespace.yaml
│   ├── microservices-demo/       # Modified microservices with persistence
│   ├── postgres/                 # PostgreSQL deployment
│   └── traffic-generator/        # k6 traffic generator
├── monitoring/
│   ├── prometheus-values.yaml
│   ├── loki-values.yaml
│   └── dashboards/               # Grafana dashboard JSONs
├── scripts/
│   ├── setup.sh                  # Complete setup script
│   └── traffic-gen.js            # k6 traffic script
└── src/
    └── orderservice-persistence/ # Modified order service code
```

## Bonus Features Implemented

1. **PostgreSQL Integration**: Order data is persisted to PostgreSQL
2. **Modified Order Service**: Saves order details, items, and timestamps
3. **Database Migrations**: Automatic schema setup
4. **Order Analytics Dashboard**: Visualize order trends and metrics
