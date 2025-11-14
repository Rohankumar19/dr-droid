# Getting Started - Complete Beginner's Guide

This guide is for those who are new to Kubernetes and want to deploy this project step by step.

## What You'll Build

By the end of this guide, you'll have:
- A working Kubernetes cluster
- Google's microservices demo (online boutique shop)
- Grafana dashboards showing metrics and logs
- Automated traffic generation
- A PostgreSQL database storing order data

## Prerequisites

### Required Software

1. **kubectl** - Kubernetes command-line tool
   - Mac: `brew install kubectl`
   - Windows: `choco install kubernetes-cli`
   - Linux: [Install guide](https://kubernetes.io/docs/tasks/tools/)

2. **helm** - Kubernetes package manager
   - Mac: `brew install helm`
   - Windows: `choco install kubernetes-helm`
   - Linux: [Install guide](https://helm.sh/docs/intro/install/)

3. **A Kubernetes cluster** - Choose ONE:
   - **Minikube** (easiest for local): [Install guide](https://minikube.sigs.k8s.io/docs/start/)
   - **Kind** (Docker-based): [Install guide](https://kind.sigs.k8s.io/docs/user/quick-start/)
   - **Cloud provider** (GKE, EKS, AKS): See CLOUD_DEPLOYMENT.md

### Verify Installation

```bash
# Check kubectl
kubectl version --client

# Check helm
helm version

# Check cluster access
kubectl cluster-info
```

## Step-by-Step Deployment

### Step 1: Start Your Kubernetes Cluster

#### Option A: Minikube (Recommended for Beginners)

```bash
# Start minikube with enough resources
minikube start --cpus=4 --memory=8192 --disk-size=40g

# Verify it's running
kubectl get nodes
```

You should see one node in "Ready" status.

#### Option B: Kind

```bash
# Create cluster
kind create cluster --config kind-config.yaml --name microservices-demo

# Verify it's running
kubectl get nodes
```

### Step 2: Clone or Download This Repository

```bash
# If using git
git clone <your-repo-url>
cd microservices-demo-k8s

# Or download and extract the ZIP file
```

### Step 3: Run the Setup Script

#### On Linux/Mac:

```bash
# Make script executable
chmod +x scripts/setup.sh

# Run setup
./scripts/setup.sh
```

#### On Windows:

```powershell
# Run PowerShell as Administrator
.\scripts\setup.ps1
```

**What the script does:**
1. Adds Helm repositories
2. Creates Kubernetes namespaces
3. Deploys PostgreSQL database
4. Deploys all microservices
5. Installs Prometheus and Grafana
6. Installs Loki for logs
7. Starts traffic generator

**Expected time:** 5-10 minutes

### Step 4: Wait for Everything to Start

```bash
# Watch pods starting up
kubectl get pods -n microservices-demo -w

# Press Ctrl+C when all pods show "Running"
```

All pods should eventually show status "Running" or "Completed".

### Step 5: Access Grafana

#### Open a new terminal and run:

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Keep this terminal open!

#### Open your browser:

Go to: http://localhost:3000

**Login credentials:**
- Username: `admin`
- Password: `prom-operator`

### Step 6: Explore Dashboards

In Grafana:

1. Click the menu icon (☰) on the left
2. Click "Dashboards"
3. You'll see several dashboards:
   - Kubernetes Cluster Monitoring
   - Kubernetes Pods
   - Node Exporter
   - Application Metrics
   - Order Analytics

Click on any dashboard to view metrics!

### Step 7: View Logs

1. In Grafana, click "Explore" (compass icon) on the left
2. Select "Loki" from the dropdown at the top
3. Click "Log browser" and select:
   - namespace: `microservices-demo`
   - app: `frontend`
4. Click "Show logs"

You should see logs from the frontend service!

### Step 8: Access the Application

#### Open another new terminal:

```bash
kubectl port-forward -n microservices-demo svc/frontend 8080:80
```

#### Open your browser:

Go to: http://localhost:8080

You should see the online boutique shop! Try browsing products.

### Step 9: Check the Database

```bash
# Connect to PostgreSQL
kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders

# Run a query
SELECT COUNT(*) FROM orders;

# Exit
\q
```

## Understanding What You Built

### Architecture Overview

```
Your Computer
    │
    ├─ Browser → http://localhost:3000 → Grafana (monitoring)
    ├─ Browser → http://localhost:8080 → Frontend (shop)
    │
    └─ kubectl → Kubernetes Cluster
                    │
                    ├─ microservices-demo namespace
                    │   ├─ 10 microservices (shop)
                    │   ├─ PostgreSQL (database)
                    │   └─ k6 (traffic generator)
                    │
                    └─ monitoring namespace
                        ├─ Prometheus (metrics)
                        ├─ Loki (logs)
                        └─ Grafana (dashboards)
```

### What Each Component Does

**Microservices (in microservices-demo namespace):**
- **Frontend**: The web interface you see
- **Checkout**: Processes orders
- **Cart**: Manages shopping cart
- **Product Catalog**: Lists products
- **Currency**: Converts currencies
- **Payment**: Processes payments
- **Shipping**: Calculates shipping
- **Email**: Sends emails
- **Recommendation**: Suggests products
- **Ad**: Shows advertisements
- **Redis**: Stores cart data
- **PostgreSQL**: Stores order data (bonus feature)

**Monitoring (in monitoring namespace):**
- **Prometheus**: Collects metrics (CPU, memory, requests)
- **Loki**: Collects logs
- **Grafana**: Shows dashboards
- **Promtail**: Sends logs to Loki

**Traffic Generator:**
- **k6**: Simulates users shopping (runs every 15 minutes)

## Common Tasks

### View All Pods

```bash
# Microservices
kubectl get pods -n microservices-demo

# Monitoring
kubectl get pods -n monitoring
```

### View Logs

```bash
# Frontend logs
kubectl logs -n microservices-demo -l app=frontend --tail=50

# Any pod logs
kubectl logs -n microservices-demo <pod-name>
```

### Restart a Service

```bash
kubectl rollout restart deployment/frontend -n microservices-demo
```

### Check Resource Usage

```bash
kubectl top pods -n microservices-demo
kubectl top nodes
```

### Scale a Service

```bash
# Scale frontend to 3 replicas
kubectl scale deployment/frontend --replicas=3 -n microservices-demo
```

## Troubleshooting

### Problem: Pods Not Starting

**Check what's wrong:**
```bash
kubectl describe pod <pod-name> -n microservices-demo
```

**Common causes:**
- Not enough resources (CPU/memory)
- Image pull errors
- Configuration errors

**Solution:**
- For minikube: Restart with more resources
- Check pod events in describe output

### Problem: Can't Access Grafana

**Check if port-forward is running:**
```bash
# Should show the port-forward command
ps aux | grep port-forward
```

**Solution:**
- Make sure port-forward command is running
- Try a different port: `kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80`
- Access at http://localhost:3001

### Problem: No Metrics in Grafana

**Wait a few minutes** - Prometheus needs time to scrape metrics.

**Check Prometheus:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Visit http://localhost:9090/targets - all should be "UP"

### Problem: No Logs in Grafana

**Check Loki:**
```bash
kubectl logs -n monitoring -l app=loki
```

**Check Promtail:**
```bash
kubectl logs -n monitoring -l app=promtail
```

### Problem: Database Empty

**Check if traffic generator ran:**
```bash
kubectl get jobs -n microservices-demo
```

**Manually trigger traffic:**
```bash
kubectl create job --from=cronjob/k6-load-test k6-manual -n microservices-demo
```

## Next Steps

### 1. Explore Dashboards

- Try different time ranges
- Create custom dashboards
- Add new panels

### 2. Generate More Traffic

```bash
# Run traffic generator manually
kubectl create job --from=cronjob/k6-load-test k6-test-$(date +%s) -n microservices-demo
```

### 3. Query the Database

```bash
kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders
```

Try queries from DATABASE_QUERIES.md

### 4. Expose Publicly

See CLOUD_DEPLOYMENT.md for options to expose Grafana publicly.

### 5. Learn More

- Read ARCHITECTURE.md to understand the system
- Read QUICK_REFERENCE.md for useful commands
- Experiment with scaling and configuration

## Cleanup

When you're done:

```bash
# Run cleanup script
./scripts/cleanup.sh

# Or stop minikube
minikube stop

# Or delete kind cluster
kind delete cluster --name microservices-demo
```

## Getting Help

### Check Status

```bash
# Overall cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Specific namespace
kubectl get all -n microservices-demo
kubectl get all -n monitoring
```

### View Events

```bash
kubectl get events -n microservices-demo --sort-by='.lastTimestamp'
```

### Describe Resources

```bash
kubectl describe pod <pod-name> -n microservices-demo
kubectl describe svc <service-name> -n microservices-demo
```

## Understanding Kubernetes Basics

### Key Concepts

**Pod**: Smallest unit, runs one or more containers
**Deployment**: Manages pods, handles scaling and updates
**Service**: Network endpoint to access pods
**Namespace**: Logical grouping of resources
**ConfigMap**: Configuration data
**Secret**: Sensitive data (passwords, keys)
**PersistentVolume**: Storage that persists beyond pod lifecycle

### Useful Commands

```bash
# Get resources
kubectl get <resource-type>
kubectl get pods
kubectl get services
kubectl get deployments

# Describe resource
kubectl describe <resource-type> <name>

# View logs
kubectl logs <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- <command>

# Port forward
kubectl port-forward <pod-name> <local-port>:<pod-port>

# Delete resource
kubectl delete <resource-type> <name>
```

## Tips for Success

1. **Be patient** - First deployment takes 5-10 minutes
2. **Check logs** - Most issues are visible in pod logs
3. **Use describe** - `kubectl describe` shows detailed info
4. **Monitor resources** - Use `kubectl top` to check usage
5. **Read documentation** - Each .md file has specific info
6. **Experiment** - It's safe to break things and restart

## What to Submit

Once everything is working:

1. Take screenshots of:
   - Grafana dashboards showing metrics
   - Grafana showing logs
   - `kubectl get pods` output
   - Database query results

2. Prepare access information:
   - Dashboard URL (if public)
   - Login credentials
   - Repository link

3. Send email to: siddarth@drdroid.io

See SUBMISSION_CHECKLIST.md for complete checklist.

## Congratulations! 🎉

You've successfully deployed a complete microservices application with monitoring!

You now have:
- ✅ 10 microservices running
- ✅ Metrics collection and visualization
- ✅ Log aggregation and search
- ✅ Automated traffic generation
- ✅ Database persistence
- ✅ Production-ready monitoring stack

This is a real-world setup used by companies in production!
