# 🚀 START HERE - Complete Guide

Welcome! This document will guide you through deploying and verifying the microservices-demo project.

## 📋 What You're Building

A complete Kubernetes deployment with:
- ✅ 10 microservices (Google's Online Boutique)
- ✅ Monitoring (Prometheus + Grafana)
- ✅ Logging (Loki)
- ✅ Traffic generation (k6)
- ✅ Database persistence (PostgreSQL) - Bonus
- ✅ Analytics dashboards - Bonus

**Time to deploy:** 5-10 minutes  
**Time to verify:** 5 minutes  
**Total time:** 15-20 minutes

---

## 🎯 Quick Start (3 Steps)

### Step 1: Deploy Everything

**Linux/Mac:**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

**Windows:**
```powershell
.\scripts\setup.ps1
```

**Wait 5-10 minutes** for everything to deploy.

### Step 2: Verify It's Working

**Linux/Mac:**
```bash
chmod +x scripts/verify.sh
./scripts/verify.sh
```

**Windows:**
```powershell
.\scripts\verify.ps1
```

**Expected:** All green checkmarks ✓

### Step 3: Access Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Open browser:** http://localhost:3000  
**Login:** admin / prom-operator

**That's it!** You're done! 🎉

---

## 📚 Documentation Guide

We have 14 comprehensive guides. Here's when to use each:

### For Getting Started
- **[START_HERE.md](START_HERE.md)** ← You are here
- **[README.md](README.md)** - Project overview and quick start
- **[GETTING_STARTED.md](GETTING_STARTED.md)** - Complete beginner's guide

### For Deployment
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Detailed deployment steps
- **[CLOUD_DEPLOYMENT.md](CLOUD_DEPLOYMENT.md)** - Deploy on GKE, EKS, AKS, etc.

### For Verification
- **[HOW_TO_CHECK.md](HOW_TO_CHECK.md)** - Quick verification guide ⭐
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Comprehensive testing

### For Daily Use
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Common commands
- **[DATABASE_QUERIES.md](DATABASE_QUERIES.md)** - SQL examples

### For Understanding
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Complete overview

### For Submission
- **[SUBMISSION.md](SUBMISSION.md)** - Assignment submission doc
- **[SUBMISSION_CHECKLIST.md](SUBMISSION_CHECKLIST.md)** - Pre-submission checklist

---

## 🔍 How to Check If It's Working

### Quick Check (30 seconds)

```bash
# Run verification script
./scripts/verify.sh  # or .\scripts\verify.ps1 on Windows
```

If you see all ✓ (green checkmarks), everything works!

### Manual Check (2 minutes)

```bash
# 1. Check pods
kubectl get pods -n microservices-demo
# All should be "Running"

# 2. Check monitoring
kubectl get pods -n monitoring
# All should be "Running"

# 3. Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Visit http://localhost:3000
```

**See [HOW_TO_CHECK.md](HOW_TO_CHECK.md) for detailed verification.**

---

## 🎓 Learning Path

### If you're new to Kubernetes:

1. Read [GETTING_STARTED.md](GETTING_STARTED.md)
2. Run the setup script
3. Follow the verification steps
4. Explore Grafana dashboards
5. Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system

### If you're experienced:

1. Read [README.md](README.md)
2. Run `./scripts/setup.sh`
3. Run `./scripts/verify.sh`
4. Check [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for commands
5. Review [SUBMISSION.md](SUBMISSION.md) for assignment details

---

## 🎯 What to Do After Deployment

### 1. Explore Grafana (5 minutes)

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Visit http://localhost:3000 (admin / prom-operator)

**Check these dashboards:**
- Kubernetes Cluster Monitoring
- Application Metrics
- Order Analytics (bonus)

**View logs:**
- Click "Explore" → Select "Loki"
- Query: `{namespace="microservices-demo"}`

### 2. Try the Application (3 minutes)

```bash
kubectl port-forward -n microservices-demo svc/frontend 8080:80
```

Visit http://localhost:8080

**Try these actions:**
- Browse products
- Add items to cart
- Complete checkout

### 3. Check the Database (2 minutes)

```bash
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders
```

**Run queries:**
```sql
-- Count orders
SELECT COUNT(*) FROM orders;

-- View recent orders
SELECT * FROM orders ORDER BY created_at DESC LIMIT 5;

-- Exit
\q
```

### 4. Monitor Traffic (1 minute)

```bash
# Check traffic generator
kubectl get jobs,cronjobs -n microservices-demo

# View traffic logs
kubectl logs -n microservices-demo -l app=k6-load-test --tail=50
```

---

## 📊 What You Should See

### In Grafana Dashboards:

✅ **Kubernetes Cluster Monitoring:**
- Node CPU usage: 20-60%
- Memory usage: 40-70%
- Pod count: 20+
- Network traffic: Active

✅ **Application Metrics:**
- Request rates: 10-50 req/s
- Error rate: < 5%
- Pod resources: Stable
- Active pods: 13

✅ **Logs (in Explore):**
- Frontend logs showing HTTP requests
- Checkout logs showing orders
- Multiple services logging
- Recent timestamps

### In Application (http://localhost:8080):

✅ **Homepage:**
- Product grid with images
- Navigation working
- Cart icon visible

✅ **Product Page:**
- Product details
- Add to cart button
- Recommendations

✅ **Cart:**
- Items listed
- Quantities adjustable
- Checkout button

### In Database:

✅ **Tables:**
```sql
orders       -- Order records
order_items  -- Order line items
```

✅ **Data (after traffic):**
- Orders with IDs, amounts, timestamps
- Order items with products, quantities

---

## 🐛 Troubleshooting

### Problem: Pods not starting

```bash
kubectl get pods -n microservices-demo
kubectl describe pod <pod-name> -n microservices-demo
```

**Common causes:**
- Not enough resources → Increase cluster resources
- Image pull errors → Check internet connection
- Configuration errors → Check logs

### Problem: Can't access Grafana

```bash
# Check Grafana pod
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Check logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

**Fix:** Make sure port-forward is running

### Problem: No data in dashboards

**Wait 2-3 minutes** - Prometheus needs time to scrape

**Check Prometheus targets:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Visit http://localhost:9090/targets

### Problem: Database empty

**Wait for traffic** - k6 runs every 15 minutes

**Manually trigger:**
```bash
kubectl create job --from=cronjob/k6-load-test k6-manual -n microservices-demo
```

**See [TESTING_GUIDE.md](TESTING_GUIDE.md) for more troubleshooting.**

---

## 📝 Submission Checklist

Before submitting to siddarth@drdroid.io:

- [ ] All pods are Running
- [ ] Grafana is accessible
- [ ] Dashboards show data
- [ ] Logs are visible
- [ ] Application works
- [ ] Database has tables
- [ ] Traffic generator is running
- [ ] Verification script passes

**See [SUBMISSION_CHECKLIST.md](SUBMISSION_CHECKLIST.md) for complete list.**

---

## 🎁 Bonus Features

This project includes bonus features for guaranteed interview:

✅ **Persistence Layer:**
- PostgreSQL database
- Order data storage
- Automatic schema setup

✅ **Analytics Dashboard:**
- Order count and revenue
- Product analytics
- Customer insights

✅ **Public Access Ready:**
- LoadBalancer configuration
- NodePort option
- Ingress setup guide

**See [SUBMISSION.md](SUBMISSION.md) for details.**

---

## 🔗 Quick Links

### Essential Commands

```bash
# Deploy
./scripts/setup.sh

# Verify
./scripts/verify.sh

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access App
kubectl port-forward -n microservices-demo svc/frontend 8080:80

# Check Database
kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders

# View Logs
kubectl logs -n microservices-demo -l app=frontend --tail=50

# Cleanup
./scripts/cleanup.sh
```

### Essential URLs

- **Grafana:** http://localhost:3000 (admin / prom-operator)
- **Application:** http://localhost:8080
- **Prometheus:** http://localhost:9090 (via port-forward)

---

## 📖 Documentation Index

| Document | Purpose | When to Read |
|----------|---------|--------------|
| START_HERE.md | Overview & quick start | First time |
| README.md | Project overview | First time |
| GETTING_STARTED.md | Beginner's guide | If new to K8s |
| HOW_TO_CHECK.md | Verification guide | After deployment |
| TESTING_GUIDE.md | Comprehensive testing | Before submission |
| DEPLOYMENT_GUIDE.md | Detailed deployment | For manual setup |
| CLOUD_DEPLOYMENT.md | Cloud providers | For cloud deployment |
| QUICK_REFERENCE.md | Common commands | Daily use |
| DATABASE_QUERIES.md | SQL examples | When using DB |
| ARCHITECTURE.md | System design | To understand |
| PROJECT_SUMMARY.md | Complete overview | For reference |
| SUBMISSION.md | Assignment details | Before submitting |
| SUBMISSION_CHECKLIST.md | Pre-submission | Before submitting |

---

## 🎯 Success Criteria

You're ready to submit when:

1. ✅ Verification script shows all green ✓
2. ✅ Grafana shows metrics and logs
3. ✅ Application is accessible and working
4. ✅ Database has tables and (optionally) data
5. ✅ No critical errors in pods
6. ✅ Documentation is clear

**If all above are true, congratulations!** 🎉

---

## 💡 Tips

1. **Be patient** - First deployment takes 5-10 minutes
2. **Check logs** - Most issues are visible in pod logs
3. **Use verify script** - Fastest way to check everything
4. **Read HOW_TO_CHECK.md** - Quick verification guide
5. **Don't panic** - Everything can be restarted/redeployed

---

## 🆘 Need Help?

1. **Quick check:** Run `./scripts/verify.sh`
2. **Detailed testing:** Read [TESTING_GUIDE.md](TESTING_GUIDE.md)
3. **Troubleshooting:** Read [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
4. **Commands:** Read [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

---

## 🚀 Next Steps

1. ✅ Deploy: `./scripts/setup.sh`
2. ✅ Verify: `./scripts/verify.sh`
3. ✅ Explore: Access Grafana and application
4. ✅ Test: Follow [HOW_TO_CHECK.md](HOW_TO_CHECK.md)
5. ✅ Submit: Follow [SUBMISSION_CHECKLIST.md](SUBMISSION_CHECKLIST.md)

**Good luck with your submission!** 🎉

---

**Questions?** Check the relevant documentation file above or review the troubleshooting sections.
