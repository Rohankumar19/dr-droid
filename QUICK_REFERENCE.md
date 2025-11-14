# Quick Reference Guide

## Common Commands

### Deployment
```bash
# Full setup
./scripts/setup.sh                    # Linux/Mac
.\scripts\setup.ps1                   # Windows

# Check deployment status
kubectl get pods -n microservices-demo
kubectl get pods -n monitoring
```

### Access Services
```bash
# Grafana (metrics & logs)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# → http://localhost:3000 (admin / prom-operator)

# Application frontend
kubectl port-forward -n microservices-demo svc/frontend 8080:80
# → http://localhost:8080

# Prometheus (direct access)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# → http://localhost:9090
```

### Database Operations
```bash
# Connect to PostgreSQL
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders

# Quick queries
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "SELECT COUNT(*) FROM orders;"

kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "SELECT * FROM orders ORDER BY created_at DESC LIMIT 5;"

# Database stats
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "
    SELECT 
      COUNT(*) as total_orders,
      SUM(total_amount) as total_revenue,
      AVG(total_amount) as avg_order_value,
      MIN(created_at) as first_order,
      MAX(created_at) as last_order
    FROM orders;"
```

### Monitoring
```bash
# View logs
kubectl logs -n microservices-demo -l app=frontend --tail=50 -f
kubectl logs -n microservices-demo -l app=order-persistence --tail=50 -f
kubectl logs -n microservices-demo -l app=k6-load-test --tail=50

# Check metrics endpoint
kubectl exec -n microservices-demo deployment/frontend -- wget -qO- localhost:8080/metrics

# View Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

### Traffic Generation
```bash
# Check traffic generator status
kubectl get jobs -n microservices-demo
kubectl get cronjobs -n microservices-demo

# Run traffic test manually
kubectl create job --from=cronjob/k6-load-test k6-manual-test -n microservices-demo

# View traffic logs
kubectl logs -n microservices-demo -l app=k6-load-test --tail=100
```

### Troubleshooting
```bash
# Pod not starting
kubectl describe pod <pod-name> -n microservices-demo
kubectl logs <pod-name> -n microservices-demo --previous

# Service not accessible
kubectl get svc -n microservices-demo
kubectl describe svc frontend -n microservices-demo

# Check events
kubectl get events -n microservices-demo --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n microservices-demo
kubectl top nodes

# Restart a deployment
kubectl rollout restart deployment/frontend -n microservices-demo
```

### Scaling
```bash
# Scale a service
kubectl scale deployment/frontend --replicas=3 -n microservices-demo

# Autoscaling
kubectl autoscale deployment/frontend --cpu-percent=50 --min=2 --max=10 -n microservices-demo
```

### Cleanup
```bash
# Full cleanup
./scripts/cleanup.sh

# Partial cleanup (keep monitoring)
kubectl delete -f k8s/microservices-demo/
kubectl delete -f k8s/postgres/
kubectl delete -f k8s/traffic-generator/
```

## Grafana Dashboards

### Pre-installed Dashboards
1. **Kubernetes Cluster Monitoring** (ID: 7249)
   - Node CPU, memory, disk usage
   - Cluster-wide metrics
   - Pod distribution

2. **Kubernetes Pods** (ID: 6417)
   - Per-pod CPU and memory
   - Network I/O
   - Pod restarts

3. **Node Exporter** (ID: 1860)
   - Detailed node metrics
   - System-level monitoring

4. **Application Metrics** (Custom)
   - Request rates by service
   - Error rates
   - Resource usage

5. **Order Analytics** (Custom - Bonus)
   - Order counts and revenue
   - Product analytics
   - Currency distribution

### Creating Custom Dashboards
1. Go to Grafana → Dashboards → New Dashboard
2. Add Panel
3. Select data source (Prometheus or Loki)
4. Write query
5. Configure visualization
6. Save dashboard

### Example Queries

**Prometheus (Metrics)**:
```promql
# Request rate
rate(http_requests_total{namespace="microservices-demo"}[5m])

# Error rate
rate(http_requests_total{namespace="microservices-demo",status=~"5.."}[5m])

# CPU usage
rate(container_cpu_usage_seconds_total{namespace="microservices-demo"}[5m])

# Memory usage
container_memory_working_set_bytes{namespace="microservices-demo"}

# Pod count
count(kube_pod_status_phase{namespace="microservices-demo",phase="Running"})
```

**Loki (Logs)**:
```logql
# All logs from namespace
{namespace="microservices-demo"}

# Logs from specific app
{namespace="microservices-demo",app="frontend"}

# Error logs
{namespace="microservices-demo"} |= "error"

# JSON log parsing
{namespace="microservices-demo"} | json | level="error"
```

## Exposing Services Publicly

### Option 1: LoadBalancer (Cloud)
```bash
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc prometheus-grafana -n monitoring -w
```

### Option 2: NodePort (Self-hosted)
```bash
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "nodePort": 30080}]}}'
# Access via http://<node-ip>:30080
```

### Option 3: Ingress (Production)
```bash
# Install ingress controller (nginx)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Create ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
  - host: grafana.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-grafana
            port:
              number: 80
EOF
```

## Performance Tuning

### Increase Resources
```bash
# Edit deployment
kubectl edit deployment/frontend -n microservices-demo

# Or patch
kubectl patch deployment frontend -n microservices-demo -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "server",
          "resources": {
            "requests": {"cpu": "200m", "memory": "128Mi"},
            "limits": {"cpu": "500m", "memory": "256Mi"}
          }
        }]
      }
    }
  }
}'
```

### Optimize PostgreSQL
```bash
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "
    CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);
    CREATE INDEX CONCURRENTLY idx_order_items_product_id ON order_items(product_id);
    VACUUM ANALYZE orders;
    VACUUM ANALYZE order_items;"
```

## Backup & Restore

### PostgreSQL Backup
```bash
# Backup
kubectl exec -n microservices-demo deployment/postgres -- \
  pg_dump -U orderuser orders > backup.sql

# Restore
kubectl exec -i -n microservices-demo deployment/postgres -- \
  psql -U orderuser orders < backup.sql
```

### Grafana Dashboards Backup
```bash
# Export dashboard JSON via Grafana UI
# Or use API
curl -H "Authorization: Bearer <api-key>" \
  http://localhost:3000/api/dashboards/uid/<dashboard-uid> > dashboard.json
```

## Useful Links

- [Microservices Demo](https://github.com/GoogleCloudPlatform/microservices-demo)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [Loki Docs](https://grafana.com/docs/loki/)
- [k6 Docs](https://k6.io/docs/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
