# Testing & Verification Guide

This guide will help you verify that all components are working correctly.

## Pre-Deployment Checks

### 1. Verify Prerequisites

```bash
# Check kubectl
kubectl version --client
# Should show client version

# Check helm
helm version
# Should show version 3.x

# Check cluster access
kubectl cluster-info
# Should show cluster endpoint

# Check cluster nodes
kubectl get nodes
# Should show at least 1 node in Ready state
```

## Deployment Verification

### Step 1: Run Setup Script

**Linux/Mac:**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

**Windows:**
```powershell
.\scripts\setup.ps1
```

**Expected Output:**
- "Adding Helm repositories..." ✓
- "Creating namespaces..." ✓
- "Deploying PostgreSQL..." ✓
- "Deploying microservices..." ✓
- "Installing Prometheus and Grafana..." ✓
- "Installing Loki..." ✓
- "Setup Complete!" ✓

### Step 2: Check All Pods Are Running

```bash
# Check microservices namespace
kubectl get pods -n microservices-demo

# Expected: All pods should show "Running" or "Completed"
# Example output:
# NAME                                     READY   STATUS    RESTARTS   AGE
# adservice-xxx                           1/1     Running   0          5m
# cartservice-xxx                         1/1     Running   0          5m
# checkoutservice-xxx                     1/1     Running   0          5m
# currencyservice-xxx                     1/1     Running   0          5m
# emailservice-xxx                        1/1     Running   0          5m
# frontend-xxx                            1/1     Running   0          5m
# order-persistence-xxx                   1/1     Running   0          5m
# paymentservice-xxx                      1/1     Running   0          5m
# postgres-xxx                            1/1     Running   0          5m
# productcatalogservice-xxx               1/1     Running   0          5m
# recommendationservice-xxx               1/1     Running   0          5m
# redis-cart-xxx                          1/1     Running   0          5m
# shippingservice-xxx                     1/1     Running   0          5m
```

```bash
# Check monitoring namespace
kubectl get pods -n monitoring

# Expected: All pods should show "Running"
# Example output:
# NAME                                                   READY   STATUS    RESTARTS   AGE
# alertmanager-prometheus-kube-prometheus-alertmanager-0 2/2     Running   0          5m
# loki-0                                                 1/1     Running   0          5m
# loki-promtail-xxx                                      1/1     Running   0          5m
# prometheus-grafana-xxx                                 3/3     Running   0          5m
# prometheus-kube-prometheus-operator-xxx                1/1     Running   0          5m
# prometheus-kube-state-metrics-xxx                      1/1     Running   0          5m
# prometheus-prometheus-kube-prometheus-prometheus-0     2/2     Running   0          5m
# prometheus-prometheus-node-exporter-xxx                1/1     Running   0          5m
```

**If any pod is not Running:**
```bash
# Check pod details
kubectl describe pod <pod-name> -n <namespace>

# Check pod logs
kubectl logs <pod-name> -n <namespace>
```

### Step 3: Check Services

```bash
# Check microservices
kubectl get svc -n microservices-demo

# Expected: All services should have ClusterIP or LoadBalancer
# Frontend should have type LoadBalancer or ClusterIP

# Check monitoring services
kubectl get svc -n monitoring

# Expected: prometheus-grafana service should exist
```

## Functional Testing

### Test 1: Access Grafana ✓

```bash
# Start port-forward (keep this running in a terminal)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Open browser:** http://localhost:3000

**Login:**
- Username: `admin`
- Password: `prom-operator`

**✅ Success Criteria:**
- Login page loads
- Can login successfully
- Grafana home page appears

**❌ If it fails:**
```bash
# Check Grafana pod
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Check service
kubectl describe svc prometheus-grafana -n monitoring
```

### Test 2: Verify Prometheus Data Source ✓

**In Grafana:**
1. Click menu (☰) → Configuration → Data Sources
2. Click "Prometheus"
3. Scroll down and click "Test"

**✅ Success Criteria:**
- Shows "Data source is working"
- Green checkmark appears

**❌ If it fails:**
```bash
# Check Prometheus
kubectl get pods -n monitoring -l app=prometheus
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0

# Check if Prometheus is accessible
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090
```

### Test 3: Verify Loki Data Source ✓

**In Grafana:**
1. Click menu (☰) → Configuration → Data Sources
2. Click "Loki"
3. Scroll down and click "Test"

**✅ Success Criteria:**
- Shows "Data source is working"
- Green checkmark appears

**❌ If it fails:**
```bash
# Check Loki
kubectl get pods -n monitoring -l app=loki
kubectl logs -n monitoring loki-0

# Check Promtail
kubectl get pods -n monitoring -l app=promtail
kubectl logs -n monitoring -l app=promtail --tail=50
```

### Test 4: View Kubernetes Metrics ✓

**In Grafana:**
1. Click menu (☰) → Dashboards
2. Click "Kubernetes Cluster Monitoring" or similar
3. Wait 10-30 seconds for data to load

**✅ Success Criteria:**
- Dashboard loads without errors
- Graphs show data (not empty)
- CPU usage visible
- Memory usage visible
- Pod count visible

**❌ If no data:**
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
# All targets should be "UP"

# Check if metrics are being scraped
# Visit http://localhost:9090/graph
# Query: up
# Should show multiple results
```

### Test 5: View Application Logs ✓

**In Grafana:**
1. Click "Explore" (compass icon) on left sidebar
2. Select "Loki" from dropdown at top
3. Click "Log browser" button
4. Select: namespace = `microservices-demo`
5. Select: app = `frontend`
6. Click "Show logs"

**✅ Success Criteria:**
- Logs appear in the panel
- Can see log entries from frontend service
- Timestamps are recent
- Can filter and search logs

**❌ If no logs:**
```bash
# Check if pods are generating logs
kubectl logs -n microservices-demo -l app=frontend --tail=20

# Check Promtail is running
kubectl get pods -n monitoring -l app=promtail
kubectl logs -n monitoring -l app=promtail --tail=50

# Check Loki
kubectl logs -n monitoring loki-0 --tail=50
```

### Test 6: Access Application Frontend ✓

```bash
# Start port-forward (in a new terminal)
kubectl port-forward -n microservices-demo svc/frontend 8080:80
```

**Open browser:** http://localhost:8080

**✅ Success Criteria:**
- Online Boutique shop loads
- Can see products
- Can click on products
- Can add items to cart
- Can view cart

**❌ If it fails:**
```bash
# Check frontend pod
kubectl get pods -n microservices-demo -l app=frontend
kubectl logs -n microservices-demo -l app=frontend --tail=50

# Check frontend service
kubectl describe svc frontend -n microservices-demo

# Check if other services are running
kubectl get pods -n microservices-demo
```

### Test 7: Verify Traffic Generation ✓

```bash
# Check if k6 jobs exist
kubectl get jobs -n microservices-demo

# Expected: Should see k6-initial-load (Completed)

# Check CronJob
kubectl get cronjobs -n microservices-demo

# Expected: Should see k6-load-test

# Check recent job logs
kubectl logs -n microservices-demo -l app=k6-load-test --tail=100
```

**✅ Success Criteria:**
- Initial job completed successfully
- CronJob is scheduled
- Logs show HTTP requests being made
- No major errors in logs

**To manually trigger traffic:**
```bash
kubectl create job --from=cronjob/k6-load-test k6-manual-test -n microservices-demo

# Wait 30 seconds, then check logs
kubectl logs -n microservices-demo job/k6-manual-test
```

**❌ If traffic not generating:**
```bash
# Check job status
kubectl describe job k6-initial-load -n microservices-demo

# Check if frontend is accessible from within cluster
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- \
  curl -I http://frontend.microservices-demo.svc.cluster.local
```

### Test 8: Verify PostgreSQL Database ✓

```bash
# Connect to PostgreSQL
kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders
```

**Run these queries:**
```sql
-- Check tables exist
\dt

-- Expected output:
--              List of relations
--  Schema |    Name     | Type  |   Owner
-- --------+-------------+-------+-----------
--  public | order_items | table | orderuser
--  public | orders      | table | orderuser

-- Check if data exists (may be empty initially)
SELECT COUNT(*) FROM orders;

-- Check table structure
\d orders
\d order_items

-- Exit
\q
```

**✅ Success Criteria:**
- Can connect to database
- Tables `orders` and `order_items` exist
- No connection errors

**❌ If it fails:**
```bash
# Check PostgreSQL pod
kubectl get pods -n microservices-demo -l app=postgres
kubectl logs -n microservices-demo -l app=postgres --tail=50

# Check if init job completed
kubectl get jobs -n microservices-demo
kubectl logs -n microservices-demo job/postgres-init
```

### Test 9: Verify Order Persistence (Bonus) ✓

```bash
# Check order persistence service
kubectl get pods -n microservices-demo -l app=order-persistence
kubectl logs -n microservices-demo -l app=order-persistence --tail=50
```

**✅ Success Criteria:**
- Pod is running
- Logs show "Order persistence service started"
- No connection errors to PostgreSQL

**After some traffic has been generated:**
```bash
# Check if orders are being saved
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "SELECT COUNT(*) FROM orders;"

# View recent orders
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "SELECT * FROM orders ORDER BY created_at DESC LIMIT 5;"
```

## Performance Testing

### Test 10: Check Resource Usage ✓

```bash
# Check node resources
kubectl top nodes

# Expected: CPU and memory usage should be reasonable
# CPU: < 80%
# Memory: < 80%

# Check pod resources
kubectl top pods -n microservices-demo
kubectl top pods -n monitoring

# Expected: No pod using excessive resources
```

**✅ Success Criteria:**
- All nodes have available resources
- No pods are being throttled
- Memory usage is stable

**❌ If resources are maxed out:**
```bash
# Check which pods are using most resources
kubectl top pods -n microservices-demo --sort-by=cpu
kubectl top pods -n microservices-demo --sort-by=memory

# Consider scaling down or increasing cluster resources
```

### Test 11: Check for Errors ✓

```bash
# Check events for errors
kubectl get events -n microservices-demo --sort-by='.lastTimestamp' | grep -i error
kubectl get events -n monitoring --sort-by='.lastTimestamp' | grep -i error

# Check pod restarts
kubectl get pods -n microservices-demo -o wide
kubectl get pods -n monitoring -o wide

# Expected: RESTARTS column should be 0 or very low
```

**✅ Success Criteria:**
- No critical errors in events
- No pods in CrashLoopBackOff
- Restart count is 0 or minimal

## End-to-End Testing

### Test 12: Complete User Flow ✓

1. **Access frontend:** http://localhost:8080
2. **Browse products:** Click on a product
3. **Add to cart:** Click "Add to Cart"
4. **View cart:** Click cart icon
5. **Checkout:** Fill form and place order

**✅ Success Criteria:**
- All pages load successfully
- Can complete checkout
- Order confirmation appears

### Test 13: Verify Metrics After Traffic ✓

**In Grafana:**
1. Go to Dashboards → Application Metrics
2. Check "Request Rate by Service"
3. Check "Error Rate"

**✅ Success Criteria:**
- Request rate shows activity
- Multiple services have traffic
- Error rate is low (< 5%)

### Test 14: Verify Logs After Traffic ✓

**In Grafana Explore:**
1. Query: `{namespace="microservices-demo"} |= "checkout"`
2. Time range: Last 15 minutes

**✅ Success Criteria:**
- Can see checkout-related logs
- Logs from multiple services
- Can filter by service name

## Automated Verification Script

Save this as `verify.sh`:

```bash
#!/bin/bash

echo "=== Microservices Demo Verification ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Check namespaces
echo "1. Checking namespaces..."
if kubectl get namespace microservices-demo &> /dev/null && kubectl get namespace monitoring &> /dev/null; then
    echo -e "${GREEN}✓ Namespaces exist${NC}"
else
    echo -e "${RED}✗ Namespaces missing${NC}"
    exit 1
fi

# Test 2: Check pods in microservices-demo
echo "2. Checking microservices pods..."
NOT_RUNNING=$(kubectl get pods -n microservices-demo --no-headers | grep -v "Running\|Completed" | wc -l)
if [ "$NOT_RUNNING" -eq 0 ]; then
    echo -e "${GREEN}✓ All microservices pods running${NC}"
else
    echo -e "${RED}✗ $NOT_RUNNING pods not running${NC}"
    kubectl get pods -n microservices-demo | grep -v "Running\|Completed"
fi

# Test 3: Check pods in monitoring
echo "3. Checking monitoring pods..."
NOT_RUNNING=$(kubectl get pods -n monitoring --no-headers | grep -v "Running\|Completed" | wc -l)
if [ "$NOT_RUNNING" -eq 0 ]; then
    echo -e "${GREEN}✓ All monitoring pods running${NC}"
else
    echo -e "${RED}✗ $NOT_RUNNING pods not running${NC}"
    kubectl get pods -n monitoring | grep -v "Running\|Completed"
fi

# Test 4: Check PostgreSQL
echo "4. Checking PostgreSQL..."
if kubectl exec -n microservices-demo deployment/postgres -- psql -U orderuser -d orders -c "SELECT 1" &> /dev/null; then
    echo -e "${GREEN}✓ PostgreSQL accessible${NC}"
else
    echo -e "${RED}✗ PostgreSQL not accessible${NC}"
fi

# Test 5: Check Grafana service
echo "5. Checking Grafana service..."
if kubectl get svc prometheus-grafana -n monitoring &> /dev/null; then
    echo -e "${GREEN}✓ Grafana service exists${NC}"
else
    echo -e "${RED}✗ Grafana service missing${NC}"
fi

# Test 6: Check frontend service
echo "6. Checking frontend service..."
if kubectl get svc frontend -n microservices-demo &> /dev/null; then
    echo -e "${GREEN}✓ Frontend service exists${NC}"
else
    echo -e "${RED}✗ Frontend service missing${NC}"
fi

# Test 7: Check CronJob
echo "7. Checking traffic generator..."
if kubectl get cronjob k6-load-test -n microservices-demo &> /dev/null; then
    echo -e "${GREEN}✓ Traffic generator configured${NC}"
else
    echo -e "${YELLOW}⚠ Traffic generator not found${NC}"
fi

# Test 8: Check database tables
echo "8. Checking database schema..."
TABLES=$(kubectl exec -n microservices-demo deployment/postgres -- psql -U orderuser -d orders -c "\dt" 2>/dev/null | grep -c "orders\|order_items")
if [ "$TABLES" -eq 2 ]; then
    echo -e "${GREEN}✓ Database tables exist${NC}"
else
    echo -e "${RED}✗ Database tables missing${NC}"
fi

echo ""
echo "=== Verification Complete ==="
echo ""
echo "Next steps:"
echo "1. Access Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "2. Access Application: kubectl port-forward -n microservices-demo svc/frontend 8080:80"
echo "3. Check database: kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders"
```

**Run it:**
```bash
chmod +x verify.sh
./verify.sh
```

## Troubleshooting Common Issues

### Issue: Pods Stuck in Pending

```bash
kubectl describe pod <pod-name> -n <namespace>
```

**Common causes:**
- Insufficient resources
- PVC not bound
- Node selector mismatch

**Solution:**
```bash
# Check node resources
kubectl describe nodes

# For minikube, increase resources
minikube stop
minikube start --cpus=4 --memory=8192
```

### Issue: ImagePullBackOff

```bash
kubectl describe pod <pod-name> -n <namespace>
```

**Solution:**
- Check internet connectivity
- Verify image names are correct
- Wait and retry (may be temporary)

### Issue: CrashLoopBackOff

```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
```

**Solution:**
- Check logs for errors
- Verify configuration
- Check dependencies are running

### Issue: No Metrics in Grafana

**Check Prometheus targets:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Visit: http://localhost:9090/targets

**All targets should be UP**

### Issue: No Logs in Grafana

**Check Promtail:**
```bash
kubectl logs -n monitoring -l app=promtail --tail=100
```

**Check Loki:**
```bash
kubectl logs -n monitoring loki-0 --tail=100
```

## Success Checklist

Use this checklist before submission:

- [ ] All pods in `microservices-demo` namespace are Running
- [ ] All pods in `monitoring` namespace are Running
- [ ] Can access Grafana at http://localhost:3000
- [ ] Can login to Grafana (admin / prom-operator)
- [ ] Prometheus data source works (green checkmark)
- [ ] Loki data source works (green checkmark)
- [ ] Can see Kubernetes metrics in dashboards
- [ ] Can see application metrics in dashboards
- [ ] Can view logs in Grafana Explore
- [ ] Can access frontend at http://localhost:8080
- [ ] Can browse products and add to cart
- [ ] Traffic generator is running (CronJob exists)
- [ ] PostgreSQL is accessible
- [ ] Database tables exist (orders, order_items)
- [ ] Order persistence service is running
- [ ] No critical errors in events
- [ ] Resource usage is reasonable

**If all items are checked, you're ready to submit! ✅**

## Quick Health Check Command

```bash
# One-liner to check everything
echo "Pods:" && kubectl get pods -n microservices-demo && \
echo "" && echo "Monitoring:" && kubectl get pods -n monitoring && \
echo "" && echo "Services:" && kubectl get svc -n microservices-demo && \
echo "" && echo "Jobs:" && kubectl get jobs,cronjobs -n microservices-demo
```

## Getting Help

If you encounter issues:

1. Check the specific test that failed
2. Review the troubleshooting section
3. Check pod logs: `kubectl logs <pod-name> -n <namespace>`
4. Check events: `kubectl get events -n <namespace> --sort-by='.lastTimestamp'`
5. Refer to DEPLOYMENT_GUIDE.md for detailed instructions
