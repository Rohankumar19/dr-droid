# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                               │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                  Namespace: microservices-demo                      │ │
│  │                                                                      │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐    │ │
│  │  │   Frontend   │─────▶│  Checkout    │─────▶│   Payment    │    │ │
│  │  │  (Web UI)    │      │   Service    │      │   Service    │    │ │
│  │  └──────┬───────┘      └──────┬───────┘      └──────────────┘    │ │
│  │         │                     │                                    │ │
│  │         │                     │                                    │ │
│  │         ▼                     ▼                                    │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐    │ │
│  │  │   Product    │      │   Shipping   │      │    Email     │    │ │
│  │  │   Catalog    │      │   Service    │      │   Service    │    │ │
│  │  └──────────────┘      └──────────────┘      └──────────────┘    │ │
│  │                                                                      │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐    │ │
│  │  │     Cart     │─────▶│    Redis     │      │  Currency    │    │ │
│  │  │   Service    │      │   (Cache)    │      │   Service    │    │ │
│  │  └──────────────┘      └──────────────┘      └──────────────┘    │ │
│  │                                                                      │ │
│  │  ┌──────────────┐      ┌──────────────┐                           │ │
│  │  │Recommendation│      │      Ad      │                           │ │
│  │  │   Service    │      │   Service    │                           │ │
│  │  └──────────────┘      └──────────────┘                           │ │
│  │                                                                      │ │
│  │  ┌────────────────────────────────────────────────────────────┐   │ │
│  │  │              BONUS: Persistence Layer                       │   │ │
│  │  │                                                              │   │ │
│  │  │  ┌──────────────┐              ┌──────────────┐            │   │ │
│  │  │  │    Order     │─────────────▶│  PostgreSQL  │            │   │ │
│  │  │  │ Persistence  │              │   Database   │            │   │ │
│  │  │  │   Service    │              │              │            │   │ │
│  │  │  └──────────────┘              └──────────────┘            │   │ │
│  │  │                                                              │   │ │
│  │  │  Tables: orders, order_items                                │   │ │
│  │  └────────────────────────────────────────────────────────────┘   │ │
│  │                                                                      │ │
│  │  ┌────────────────────────────────────────────────────────────┐   │ │
│  │  │              Traffic Generation                             │   │ │
│  │  │                                                              │   │ │
│  │  │  ┌──────────────┐                                           │   │ │
│  │  │  │  k6 CronJob  │  (Runs every 15 minutes)                 │   │ │
│  │  │  │              │  Simulates user traffic                   │   │ │
│  │  │  └──────────────┘                                           │   │ │
│  │  └────────────────────────────────────────────────────────────┘   │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    Namespace: monitoring                            │ │
│  │                                                                      │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐    │ │
│  │  │  Prometheus  │◀─────│   Exporters  │      │   Promtail   │    │ │
│  │  │   (Metrics)  │      │  (Scrapers)  │      │ (Log Agent)  │    │ │
│  │  └──────┬───────┘      └──────────────┘      └──────┬───────┘    │ │
│  │         │                                             │             │ │
│  │         │                                             │             │ │
│  │         ▼                                             ▼             │ │
│  │  ┌──────────────────────────────────────────────────────────┐    │ │
│  │  │                      Grafana                              │    │ │
│  │  │                 (Visualization)                           │    │ │
│  │  │                                                            │    │ │
│  │  │  Dashboards:                                              │    │ │
│  │  │  • Kubernetes Cluster Metrics                             │    │ │
│  │  │  • Application Metrics                                    │    │ │
│  │  │  • Application Logs                                       │    │ │
│  │  │  • Order Analytics (Bonus)                                │    │ │
│  │  └──────────────────────────────────────────────────────────┘    │ │
│  │         ▲                                             ▲             │ │
│  │         │                                             │             │ │
│  │  ┌──────────────┐                            ┌──────────────┐    │ │
│  │  │  Prometheus  │                            │     Loki     │    │ │
│  │  │   Storage    │                            │   Storage    │    │ │
│  │  │    (TSDB)    │                            │  (Log Store) │    │ │
│  │  └──────────────┘                            └──────────────┘    │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ External Access
                                    ▼
                          ┌──────────────────┐
                          │   LoadBalancer   │
                          │   or NodePort    │
                          │   or Ingress     │
                          └────────┬─────────┘
                                   │
                                   ▼
                            ┌─────────────┐
                            │   Internet  │
                            │    Users    │
                            └─────────────┘
```

## Data Flow

### 1. User Traffic Flow
```
User Browser
    │
    ▼
Frontend Service (Port 80)
    │
    ├─▶ Product Catalog Service (gRPC)
    ├─▶ Currency Service (gRPC)
    ├─▶ Cart Service (gRPC) ──▶ Redis
    ├─▶ Recommendation Service (gRPC)
    └─▶ Checkout Service (gRPC)
            │
            ├─▶ Shipping Service (gRPC)
            ├─▶ Payment Service (gRPC)
            ├─▶ Email Service (gRPC)
            └─▶ Order Persistence ──▶ PostgreSQL
```

### 2. Metrics Flow
```
Application Pods
    │ (Prometheus annotations)
    ▼
Prometheus Scraper
    │ (Pull metrics every 30s)
    ▼
Prometheus TSDB
    │ (Store time-series data)
    ▼
Grafana
    │ (Query and visualize)
    ▼
Dashboard
```

### 3. Logs Flow
```
Application Pods
    │ (stdout/stderr)
    ▼
Kubernetes Logs
    │
    ▼
Promtail (DaemonSet)
    │ (Tail and parse logs)
    ▼
Loki
    │ (Store log streams)
    ▼
Grafana
    │ (Query and display)
    ▼
Log Explorer
```

### 4. Order Persistence Flow (Bonus)
```
User Checkout
    │
    ▼
Checkout Service
    │ (Place order)
    ▼
Order Persistence Service
    │ (Extract order data)
    ▼
PostgreSQL
    │ (Store in tables)
    ├─▶ orders table
    └─▶ order_items table
```

## Component Details

### Microservices (10 services)

| Service | Language | Port | Purpose |
|---------|----------|------|---------|
| Frontend | Go | 8080 | Web UI |
| Checkout | Go | 5050 | Order processing |
| Product Catalog | Go | 3550 | Product info |
| Cart | C# | 7070 | Shopping cart |
| Currency | Node.js | 7000 | Currency conversion |
| Payment | Node.js | 50051 | Payment processing |
| Shipping | Go | 50051 | Shipping quotes |
| Email | Python | 8080 | Email notifications |
| Recommendation | Python | 8080 | Product recommendations |
| Ad | Java | 9555 | Advertisements |

### Supporting Services

| Service | Purpose | Storage |
|---------|---------|---------|
| Redis | Cart session storage | In-memory |
| PostgreSQL | Order persistence (Bonus) | Persistent volume |

### Monitoring Stack

| Component | Purpose | Port |
|-----------|---------|------|
| Prometheus | Metrics collection & storage | 9090 |
| Grafana | Visualization & dashboards | 3000 |
| Loki | Log aggregation & storage | 3100 |
| Promtail | Log collection agent | - |
| Alertmanager | Alert management | 9093 |

### Traffic Generation

| Component | Purpose | Schedule |
|-----------|---------|----------|
| k6 | Load testing | Every 15 min |
| Initial Job | Immediate traffic | Once |

## Network Architecture

### Service Communication
- **Frontend ↔ Backend**: gRPC over HTTP/2
- **Cart ↔ Redis**: Redis protocol
- **Persistence ↔ PostgreSQL**: PostgreSQL protocol
- **Monitoring**: HTTP metrics endpoints

### Ports
- **Frontend**: 80 (LoadBalancer)
- **Grafana**: 80 (LoadBalancer/NodePort)
- **Prometheus**: 9090 (ClusterIP)
- **Loki**: 3100 (ClusterIP)

## Storage Architecture

### Persistent Volumes

```
PostgreSQL
├── PVC: postgres-pvc (5Gi)
└── Mount: /var/lib/postgresql/data

Prometheus
├── PVC: prometheus-storage (10Gi)
└── Mount: /prometheus

Loki
├── PVC: loki-storage (10Gi)
└── Mount: /data/loki

Grafana
├── PVC: grafana-storage (5Gi)
└── Mount: /var/lib/grafana
```

## Security Architecture

### Network Policies (Optional)
```
microservices-demo namespace:
- Allow ingress from frontend to all services
- Allow ingress from monitoring namespace (Prometheus)
- Deny all other ingress

monitoring namespace:
- Allow ingress to Grafana from LoadBalancer
- Allow ingress to Prometheus from Grafana
- Allow ingress to Loki from Grafana
- Deny all other ingress
```

### Secrets
```
PostgreSQL:
- postgres-secret (password)

Grafana:
- prometheus-grafana (admin password)
```

## Scalability

### Horizontal Scaling
```bash
# Scale frontend
kubectl scale deployment/frontend --replicas=3 -n microservices-demo

# Scale any service
kubectl scale deployment/<service> --replicas=N -n microservices-demo
```

### Autoscaling
```bash
# Enable HPA
kubectl autoscale deployment/frontend \
  --cpu-percent=50 \
  --min=2 \
  --max=10 \
  -n microservices-demo
```

### Resource Limits

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| Frontend | 100m | 200m | 64Mi | 128Mi |
| Checkout | 100m | 200m | 64Mi | 128Mi |
| Cart | 200m | 300m | 64Mi | 128Mi |
| Redis | 70m | 125m | 200Mi | 256Mi |
| PostgreSQL | 100m | 500m | 256Mi | 512Mi |
| Prometheus | 500m | 2000m | 2Gi | 4Gi |
| Grafana | 100m | 200m | 128Mi | 256Mi |

## High Availability

### Current Setup
- Single replica for most services
- Suitable for demo/development

### Production Recommendations
```yaml
Frontend: 3+ replicas
Checkout: 3+ replicas
Cart: 3+ replicas
Redis: Redis Sentinel (3 nodes)
PostgreSQL: Primary + Replica
Prometheus: 2 replicas
Grafana: 2 replicas
Loki: 3 replicas
```

## Monitoring Coverage

### Metrics Collected
- **Infrastructure**: CPU, memory, disk, network
- **Kubernetes**: Pod status, deployments, services
- **Application**: Request rate, error rate, latency
- **Database**: Connections, queries, storage
- **Custom**: Order count, revenue, product analytics

### Logs Collected
- **Application logs**: All microservices
- **System logs**: Kubernetes events
- **Access logs**: Frontend requests
- **Error logs**: All error messages

## Disaster Recovery

### Backup Strategy
```bash
# PostgreSQL backup
kubectl exec -n microservices-demo deployment/postgres -- \
  pg_dump -U orderuser orders > backup.sql

# Grafana dashboards
# Export via UI or API

# Prometheus data
# Use Thanos or Cortex for long-term storage
```

### Recovery
```bash
# Restore PostgreSQL
kubectl exec -i -n microservices-demo deployment/postgres -- \
  psql -U orderuser orders < backup.sql

# Restore Grafana
# Import dashboards via UI
```

## Performance Optimization

### Database Indexes
```sql
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
```

### Caching
- Redis for cart sessions
- Consider adding cache for product catalog
- Consider CDN for frontend assets

### Query Optimization
- Use connection pooling (pgbouncer)
- Optimize Prometheus queries
- Use Loki query optimization

## Cost Optimization

### Resource Right-Sizing
- Monitor actual usage
- Adjust requests/limits
- Use node autoscaling

### Storage Optimization
- Set retention policies
- Use compression
- Archive old data

### Network Optimization
- Use ClusterIP for internal services
- Single LoadBalancer for ingress
- Consider service mesh for advanced routing
