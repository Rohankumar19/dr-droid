# How to Check If Everything Is Working

This is a quick reference guide to verify your deployment is functioning correctly.

## Quick Verification (2 minutes)

### 1. Run Automated Verification

**Linux/Mac:**
```bash
chmod +x scripts/verify.sh
./scripts/verify.sh
```

**Windows:**
```powershell
.\scripts\verify.ps1
```

**Expected Output:**
```
=== Microservices Demo Verification ===

1. Checking namespaces...
   ✓ Namespaces exist
2. Checking microservices pods...
   ✓ All 13 microservices pods running
3. Checking monitoring pods...
   ✓ All 8 monitoring pods running
4. Checking PostgreSQL...
   ✓ PostgreSQL accessible
5. Checking Grafana service...
   ✓ Grafana service exists
6. Checking frontend service...
   ✓ Frontend service exists
7. Checking traffic generator...
   ✓ Traffic generator configured
8. Checking database schema...
   ✓ Database tables exist

=== Verification Complete ===
✓ All critical checks passed!
```

If you see all green checkmarks (✓), everything is working! 🎉

---

## Manual Verification (5 minutes)

### Step 1: Check Pods Status

```bash
kubectl get pods -n microservices-demo
```

**What to look for:**
- All pods should show `Running` or `Completed` status
- `READY` column should show `1/1` or `2/2`
- `RESTARTS` should be `0` or very low

**Example of good output:**
```
NAME                                     READY   STATUS    RESTARTS   AGE
adservice-xxx                           1/1     Running   0          10m
cartservice-xxx                         1/1     Running   0          10m
checkoutservice-xxx                     1/1     Running   0          10m
frontend-xxx                            1/1     Running   0          10m
postgres-xxx                            1/1     Running   0          10m
```

**❌ Bad signs:**
- `CrashLoopBackOff`
- `ImagePullBackOff`
- `Pending` for more than 5 minutes
- High restart count (> 5)

### Step 2: Check Monitoring Pods

```bash
kubectl get pods -n monitoring
```

**What to look for:**
- All pods should be `Running`
- Prometheus and Grafana pods are present

### Step 3: Access Grafana

```bash
# In a terminal, run:
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Open browser:** http://localhost:3000

**Login:**
- Username: `admin`
- Password: `prom-operator`

**✅ Success:** You see the Grafana home page

### Step 4: Check Metrics

**In Grafana:**
1. Click menu (☰) → Dashboards
2. Click any dashboard (e.g., "Kubernetes Cluster Monitoring")
3. Wait 10-30 seconds

**✅ Success:** You see graphs with data (not empty)

**Example of what you should see:**
- CPU usage graphs showing activity
- Memory usage graphs showing data
- Pod counts showing numbers
- Network traffic showing activity

### Step 5: Check Logs

**In Grafana:**
1. Click "Explore" (compass icon) on left
2. Select "Loki" from dropdown
3. Click "Log browser"
4. Select: namespace = `microservices-demo`, app = `frontend`
5. Click "Show logs"

**✅ Success:** You see log entries appearing

**Example log entries:**
```
2024-11-14 10:30:15 GET /product/OLJCESPC7Z 200
2024-11-14 10:30:16 GET /cart 200
2024-11-14 10:30:17 POST /cart/checkout 200
```

### Step 6: Access Application

```bash
# In a new terminal, run:
kubectl port-forward -n microservices-demo svc/frontend 8080:80
```

**Open browser:** http://localhost:8080

**✅ Success:** You see the Online Boutique shop

**Try these actions:**
1. Click on a product → Should show product details
2. Click "Add to Cart" → Should add to cart
3. Click cart icon → Should show cart contents

### Step 7: Check Database

```bash
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "SELECT COUNT(*) FROM orders;"
```

**✅ Success:** You see a number (even if it's 0)

**Example output:**
```
 count 
-------
    42
(1 row)
```

### Step 8: Check Traffic Generator

```bash
kubectl get jobs,cronjobs -n microservices-demo
```

**✅ Success:** You see:
- A completed job: `k6-initial-load`
- A cronjob: `k6-load-test`

**Example output:**
```
NAME                         COMPLETIONS   DURATION   AGE
job.batch/k6-initial-load   1/1           2m15s      15m

NAME                            SCHEDULE        SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/k6-load-test     */15 * * * *    False     0        5m              15m
```

---

## Detailed Checks

### Check Resource Usage

```bash
kubectl top nodes
kubectl top pods -n microservices-demo
```

**✅ Good:** CPU and memory usage under 80%

### Check for Errors

```bash
kubectl get events -n microservices-demo --sort-by='.lastTimestamp' | tail -20
```

**✅ Good:** No critical errors or warnings

### Check Service Endpoints

```bash
kubectl get svc -n microservices-demo
kubectl get svc -n monitoring
```

**✅ Good:** All services have ClusterIP addresses

### Check Persistent Volumes

```bash
kubectl get pvc -n microservices-demo
kubectl get pvc -n monitoring
```

**✅ Good:** All PVCs are `Bound`

---

## Common Issues and Quick Fixes

### Issue: "Connection refused" when accessing Grafana

**Check:**
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
```

**Fix:**
- Make sure port-forward is running
- Try a different port: `kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80`

### Issue: No data in Grafana dashboards

**Wait 2-3 minutes** - Prometheus needs time to scrape metrics

**Check Prometheus:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Visit http://localhost:9090/targets - all should be "UP"

### Issue: Pods stuck in "Pending"

**Check:**
```bash
kubectl describe pod <pod-name> -n microservices-demo
```

**Common cause:** Not enough resources

**Fix for minikube:**
```bash
minikube stop
minikube start --cpus=4 --memory=8192
./scripts/setup.sh
```

### Issue: Database connection failed

**Check PostgreSQL:**
```bash
kubectl logs -n microservices-demo -l app=postgres --tail=50
```

**Restart if needed:**
```bash
kubectl rollout restart deployment/postgres -n microservices-demo
```

### Issue: No logs in Grafana

**Check Loki:**
```bash
kubectl logs -n monitoring loki-0 --tail=50
```

**Check Promtail:**
```bash
kubectl logs -n monitoring -l app=promtail --tail=50
```

---

## Complete Health Check Checklist

Use this before submitting:

**Infrastructure:**
- [ ] Kubernetes cluster is running
- [ ] kubectl commands work
- [ ] Sufficient resources available

**Microservices:**
- [ ] All 13 pods in `microservices-demo` namespace are Running
- [ ] Frontend service is accessible
- [ ] Can browse products on http://localhost:8080
- [ ] Can add items to cart
- [ ] No pods in CrashLoopBackOff

**Monitoring:**
- [ ] All 8+ pods in `monitoring` namespace are Running
- [ ] Grafana is accessible at http://localhost:3000
- [ ] Can login to Grafana
- [ ] Prometheus data source works (green checkmark)
- [ ] Loki data source works (green checkmark)
- [ ] Dashboards show metrics (not empty)
- [ ] Can view logs in Explore

**Database (Bonus):**
- [ ] PostgreSQL pod is Running
- [ ] Can connect to database
- [ ] Tables `orders` and `order_items` exist
- [ ] Can query database without errors

**Traffic Generation:**
- [ ] Initial k6 job completed
- [ ] CronJob is scheduled
- [ ] Can see traffic in metrics
- [ ] Can see requests in logs

**Overall:**
- [ ] No critical errors in events
- [ ] Resource usage is reasonable
- [ ] All services are responding
- [ ] Documentation is clear

---

## One-Line Health Check

```bash
echo "=== Quick Health Check ===" && \
kubectl get pods -n microservices-demo | grep -v Running | grep -v Completed | grep -v NAME && \
kubectl get pods -n monitoring | grep -v Running | grep -v Completed | grep -v NAME && \
echo "If nothing appears above, all pods are healthy!" || echo "Check pods listed above"
```

---

## Getting Detailed Information

### View all resources
```bash
kubectl get all -n microservices-demo
kubectl get all -n monitoring
```

### View pod details
```bash
kubectl describe pod <pod-name> -n <namespace>
```

### View pod logs
```bash
kubectl logs <pod-name> -n <namespace> --tail=100
```

### View recent events
```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -20
```

---

## Success Indicators

You know everything is working when:

1. ✅ Verification script shows all green checkmarks
2. ✅ All pods are in Running state
3. ✅ Grafana loads and shows data
4. ✅ Application frontend is accessible
5. ✅ Logs are visible in Grafana
6. ✅ Database is accessible and has tables
7. ✅ Traffic generator is running
8. ✅ No critical errors in events

**If all above are true, you're ready to submit!** 🚀

---

## Need More Help?

- **Detailed testing:** See [TESTING_GUIDE.md](TESTING_GUIDE.md)
- **Troubleshooting:** See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Quick commands:** See [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Architecture:** See [ARCHITECTURE.md](ARCHITECTURE.md)

---

## Quick Command Reference

```bash
# Check everything
./scripts/verify.sh

# Check pods
kubectl get pods -n microservices-demo
kubectl get pods -n monitoring

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access Application
kubectl port-forward -n microservices-demo svc/frontend 8080:80

# Check database
kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders

# View logs
kubectl logs -n microservices-demo -l app=frontend --tail=50

# Check traffic
kubectl get jobs,cronjobs -n microservices-demo

# Check resources
kubectl top nodes
kubectl top pods -n microservices-demo
```

---

**Remember:** The verification script (`./scripts/verify.sh` or `.\scripts\verify.ps1`) is the fastest way to check everything!
