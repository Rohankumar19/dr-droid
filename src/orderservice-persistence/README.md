# Order Service Persistence Layer (Bonus)

This directory contains the modified order service that adds persistence to the Google microservices-demo.

## Overview

The persistence layer captures order data from the checkout service and stores it in PostgreSQL for analytics and reporting.

## Architecture

```
Checkout Service → Order Persistence Service → PostgreSQL
                         ↓
                   Prometheus Metrics
```

## Database Schema

### Orders Table
```sql
CREATE TABLE orders (
  order_id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  user_currency VARCHAR(10) NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Order Items Table
```sql
CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id VARCHAR(255) REFERENCES orders(order_id),
  product_id VARCHAR(255) NOT NULL,
  quantity INTEGER NOT NULL,
  cost DECIMAL(10, 2) NOT NULL
);
```

## Implementation Approaches

### Current Implementation (Sidecar Pattern)
The current implementation uses a Python sidecar container that:
1. Runs alongside the checkout service
2. Listens for order events (simulated)
3. Persists order data to PostgreSQL
4. Exposes metrics for monitoring

### Alternative Implementations

#### 1. Modify Checkout Service Directly
Fork the original checkout service and add database writes:
```go
// In checkout service (Go)
import "database/sql"

func (cs *checkoutService) PlaceOrder(ctx context.Context, req *pb.PlaceOrderRequest) (*pb.PlaceOrderResponse, error) {
    // ... existing order logic ...
    
    // Add persistence
    err := cs.saveOrderToDatabase(order)
    if err != nil {
        log.Printf("Failed to persist order: %v", err)
        // Don't fail the order, just log
    }
    
    return &pb.PlaceOrderResponse{Order: order}, nil
}
```

#### 2. Event-Driven Architecture
Use message queue (Kafka/RabbitMQ) for async persistence:
```
Checkout Service → Kafka Topic → Order Persistence Worker → PostgreSQL
```

#### 3. Service Mesh Integration
Use Istio/Linkerd to intercept and log order requests.

## Metrics Exposed

The persistence service exposes Prometheus metrics:
- `orders_persisted_total`: Total orders saved
- `orders_persist_errors_total`: Failed persistence attempts
- `order_persist_duration_seconds`: Time to save orders

## Testing

### Verify Database Connection
```bash
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "SELECT version();"
```

### Check Order Data
```bash
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "SELECT COUNT(*) FROM orders;"
```

### View Recent Orders
```bash
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "SELECT * FROM orders ORDER BY created_at DESC LIMIT 5;"
```

## Forking Instructions

To create a proper fork with persistence:

1. Fork the original repository:
```bash
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
cd microservices-demo
```

2. Modify the checkout service (src/checkoutservice/main.go)

3. Add database connection and persistence logic

4. Build and push custom Docker image:
```bash
docker build -t yourusername/checkoutservice:v1.0-persistence .
docker push yourusername/checkoutservice:v1.0-persistence
```

5. Update Kubernetes manifests to use your image

## Production Considerations

1. **Connection Pooling**: Use pgbouncer for connection management
2. **Retry Logic**: Implement exponential backoff for failed writes
3. **Monitoring**: Add detailed metrics and alerting
4. **Backup**: Regular PostgreSQL backups
5. **Scaling**: Consider read replicas for analytics queries
6. **Security**: Use secrets management (Vault, Sealed Secrets)
7. **Data Retention**: Implement archival strategy for old orders

## Future Enhancements

- [ ] Add order status tracking (pending, completed, cancelled)
- [ ] Implement order search API
- [ ] Add customer analytics
- [ ] Product recommendation based on order history
- [ ] Real-time order dashboard
- [ ] Export orders to data warehouse
- [ ] Add order notifications
