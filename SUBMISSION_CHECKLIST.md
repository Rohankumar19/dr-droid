# Submission Checklist

Use this checklist to ensure your submission is complete before sending to siddarth@drdroid.io

## Pre-Deployment Checklist

- [ ] Kubernetes cluster is running and accessible
- [ ] kubectl is configured and working
- [ ] helm 3.x is installed
- [ ] Sufficient cluster resources (4 CPU, 8GB RAM minimum)

## Deployment Checklist

- [ ] Run setup script successfully
  ```bash
  ./scripts/setup.sh  # or .\scripts\setup.ps1 on Windows
  ```

- [ ] All pods are running
  ```bash
  kubectl get pods -n microservices-demo
  kubectl get pods -n monitoring
  ```

- [ ] Grafana is accessible
  ```bash
  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
  # Visit http://localhost:3000
  ```

- [ ] Can login to Grafana (admin / prom-operator)

- [ ] Prometheus data source is working
  - [ ] Go to Configuration → Data Sources
  - [ ] Prometheus shows "Data source is working"

- [ ] Loki data source is working
  - [ ] Go to Configuration → Data Sources
  - [ ] Loki shows "Data source is working"

## Verification Checklist

### 1. Application Metrics (Required) ✓

- [ ] Kubernetes cluster dashboard shows data
  - [ ] Node CPU usage visible
  - [ ] Node memory usage visible
  - [ ] Pod count visible

- [ ] Application metrics dashboard shows data
  - [ ] Request rates visible
  - [ ] Error rates visible
  - [ ] Pod resource usage visible

- [ ] Can see metrics from multiple services
  - [ ] Frontend metrics
  - [ ] Checkout service metrics
  - [ ] Other microservices metrics

### 2. Application Logs (Required) ✓

- [ ] Can view logs in Grafana Explore
  - [ ] Go to Explore
  - [ ] Select Loki data source
  - [ ] Query: `{namespace="microservices-demo"}`
  - [ ] Logs are visible

- [ ] Can filter logs by service
  - [ ] Query: `{namespace="microservices-demo",app="frontend"}`
  - [ ] Frontend logs visible

- [ ] Can search logs
  - [ ] Query: `{namespace="microservices-demo"} |= "error"`
  - [ ] Error logs visible (if any)

### 3. Traffic Generation (Required) ✓

- [ ] k6 jobs are running
  ```bash
  kubectl get jobs -n microservices-demo
  kubectl get cronjobs -n microservices-demo
  ```

- [ ] Can see traffic in metrics
  - [ ] Request rates increasing
  - [ ] Multiple services receiving requests

- [ ] Can see traffic in logs
  - [ ] Frontend logs showing requests
  - [ ] Checkout logs showing activity

### 4. Persistence Layer (Bonus) ✓

- [ ] PostgreSQL is running
  ```bash
  kubectl get pods -n microservices-demo -l app=postgres
  ```

- [ ] Database schema is created
  ```bash
  kubectl exec -it -n microservices-demo deployment/postgres -- \
    psql -U orderuser -d orders -c "\dt"
  ```

- [ ] Can query orders table
  ```bash
  kubectl exec -it -n microservices-demo deployment/postgres -- \
    psql -U orderuser -d orders -c "SELECT COUNT(*) FROM orders;"
  ```

- [ ] Order persistence service is running
  ```bash
  kubectl get pods -n microservices-demo -l app=order-persistence
  ```

## Public Access Checklist (Bonus - Interview Guarantee)

Choose ONE option:

### Option A: LoadBalancer (Cloud)
- [ ] Exposed Grafana as LoadBalancer
  ```bash
  kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
  ```
- [ ] Got external IP
  ```bash
  kubectl get svc prometheus-grafana -n monitoring
  ```
- [ ] Can access via http://EXTERNAL-IP
- [ ] Grafana loads and login works

### Option B: NodePort (Self-hosted)
- [ ] Exposed Grafana as NodePort
  ```bash
  kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "nodePort": 30080}]}}'
  ```
- [ ] Opened firewall port 30080
- [ ] Can access via http://NODE-IP:30080
- [ ] Grafana loads and login works

### Option C: Ingress (Production)
- [ ] Installed ingress controller
- [ ] Created ingress resource
- [ ] Configured DNS
- [ ] Can access via http://grafana.yourdomain.com
- [ ] Grafana loads and login works

## Documentation Checklist

- [ ] README.md is clear and complete
- [ ] DEPLOYMENT_GUIDE.md has all steps
- [ ] SUBMISSION.md has all required information
- [ ] All scripts are executable (chmod +x on Linux/Mac)
- [ ] Repository is clean (no secrets, no unnecessary files)

## Email Submission Checklist

Prepare email to: siddarth@drdroid.io

Subject: "Microservices Demo Assignment Submission - [Your Name]"

Email should include:

- [ ] **Dashboard URL**
  - Public URL: http://_______________
  - OR: "Please use port-forward: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"

- [ ] **Login Credentials**
  - Username: admin
  - Password: prom-operator
  - OR: "Added siddarth@drdroid.io to team"

- [ ] **Repository Link**
  - GitHub/GitLab URL: _______________
  - OR: Attached as ZIP file

- [ ] **Brief Description**
  ```
  I have completed the microservices-demo assignment with:
  - Kubernetes deployment on [cloud provider / self-hosted]
  - Monitoring with Prometheus + Grafana
  - Logging with Loki
  - Traffic generation with k6
  - [Bonus] PostgreSQL persistence layer for orders
  - [Bonus] Public endpoint at [URL] (non-ngrok)
  
  All requirements are met and verified.
  ```

- [ ] **Screenshots** (Optional but recommended)
  - [ ] Grafana dashboard showing metrics
  - [ ] Grafana showing logs
  - [ ] kubectl get pods output
  - [ ] PostgreSQL query results (bonus)

## Final Verification

Before sending email:

- [ ] Test the public URL in incognito/private browser
- [ ] Verify login credentials work
- [ ] Check that dashboards show data
- [ ] Verify logs are visible
- [ ] Test from different network (mobile hotspot) if possible

## Post-Submission

- [ ] Keep cluster running for at least 1 week
- [ ] Monitor for any issues
- [ ] Be ready to provide additional access if needed
- [ ] Check email for response

## Troubleshooting Before Submission

### No metrics showing
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
# All targets should be UP
```

### No logs showing
```bash
# Check Loki
kubectl logs -n monitoring -l app=loki
# Check Promtail
kubectl logs -n monitoring -l app=promtail
```

### Grafana not accessible
```bash
# Check Grafana pod
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

### Database empty
```bash
# Check order persistence service
kubectl logs -n microservices-demo -l app=order-persistence
# Check if traffic generator is running
kubectl get jobs -n microservices-demo
```

## Time Estimate

- [ ] Setup: 30-45 minutes
- [ ] Verification: 15-30 minutes
- [ ] Public exposure: 10-20 minutes
- [ ] Documentation review: 10 minutes
- [ ] Email preparation: 10 minutes

**Total: 1.5-2 hours**

## Success Criteria

You're ready to submit when:

✅ All pods are running and healthy
✅ Grafana shows metrics from Prometheus
✅ Grafana shows logs from Loki
✅ Traffic generator is creating load
✅ PostgreSQL has order data (bonus)
✅ Public URL works (bonus)
✅ Documentation is complete
✅ Email is prepared

## Contact

If you encounter issues:
1. Check DEPLOYMENT_GUIDE.md troubleshooting section
2. Check QUICK_REFERENCE.md for common commands
3. Review logs: `kubectl logs -n <namespace> <pod-name>`
4. Check events: `kubectl get events -n <namespace>`

Good luck! 🚀
