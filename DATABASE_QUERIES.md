# Database Queries - Order Analytics

This document contains useful SQL queries for analyzing order data in the PostgreSQL database.

## Connecting to Database

```bash
# Interactive shell
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders

# Single query
kubectl exec -it -n microservices-demo deployment/postgres -- \
  psql -U orderuser -d orders -c "YOUR_QUERY_HERE"
```

## Schema Information

### View Tables
```sql
\dt
```

### View Table Structure
```sql
\d orders
\d order_items
```

### View Indexes
```sql
\di
```

## Basic Queries

### Count Total Orders
```sql
SELECT COUNT(*) as total_orders FROM orders;
```

### View Recent Orders
```sql
SELECT 
    order_id,
    user_id,
    user_currency,
    total_amount,
    created_at
FROM orders
ORDER BY created_at DESC
LIMIT 10;
```

### View Order Details with Items
```sql
SELECT 
    o.order_id,
    o.user_id,
    o.total_amount,
    o.user_currency,
    o.created_at,
    oi.product_id,
    oi.quantity,
    oi.cost
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
ORDER BY o.created_at DESC
LIMIT 20;
```

## Analytics Queries

### Revenue Statistics
```sql
SELECT 
    COUNT(*) as total_orders,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value,
    MIN(total_amount) as min_order,
    MAX(total_amount) as max_order
FROM orders;
```

### Revenue by Currency
```sql
SELECT 
    user_currency,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM orders
GROUP BY user_currency
ORDER BY total_revenue DESC;
```

### Orders by Hour
```sql
SELECT 
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue
FROM orders
GROUP BY hour
ORDER BY hour DESC
LIMIT 24;
```

### Orders by Day
```sql
SELECT 
    DATE(created_at) as date,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue,
    AVG(total_amount) as avg_order_value
FROM orders
GROUP BY date
ORDER BY date DESC;
```

### Top Products by Quantity
```sql
SELECT 
    product_id,
    COUNT(*) as times_ordered,
    SUM(quantity) as total_quantity,
    SUM(cost) as total_revenue
FROM order_items
GROUP BY product_id
ORDER BY total_quantity DESC
LIMIT 10;
```

### Top Products by Revenue
```sql
SELECT 
    product_id,
    COUNT(*) as times_ordered,
    SUM(quantity) as total_quantity,
    SUM(cost) as total_revenue,
    AVG(cost) as avg_revenue_per_order
FROM order_items
GROUP BY product_id
ORDER BY total_revenue DESC
LIMIT 10;
```

### Average Items per Order
```sql
SELECT 
    AVG(item_count) as avg_items_per_order,
    MIN(item_count) as min_items,
    MAX(item_count) as max_items
FROM (
    SELECT 
        order_id,
        COUNT(*) as item_count
    FROM order_items
    GROUP BY order_id
) as order_counts;
```

### Top Customers by Order Count
```sql
SELECT 
    user_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent,
    AVG(total_amount) as avg_order_value,
    MAX(created_at) as last_order_date
FROM orders
GROUP BY user_id
ORDER BY order_count DESC
LIMIT 10;
```

### Top Customers by Revenue
```sql
SELECT 
    user_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent,
    AVG(total_amount) as avg_order_value,
    MAX(created_at) as last_order_date
FROM orders
GROUP BY user_id
ORDER BY total_spent DESC
LIMIT 10;
```

## Time-Based Analytics

### Orders in Last Hour
```sql
SELECT COUNT(*) as orders_last_hour
FROM orders
WHERE created_at > NOW() - INTERVAL '1 hour';
```

### Orders Today
```sql
SELECT COUNT(*) as orders_today
FROM orders
WHERE DATE(created_at) = CURRENT_DATE;
```

### Revenue Today
```sql
SELECT 
    COUNT(*) as orders_today,
    SUM(total_amount) as revenue_today,
    AVG(total_amount) as avg_order_today
FROM orders
WHERE DATE(created_at) = CURRENT_DATE;
```

### Orders This Week
```sql
SELECT 
    DATE(created_at) as date,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue
FROM orders
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY date
ORDER BY date;
```

### Hourly Order Rate (Last 24 Hours)
```sql
SELECT 
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as orders,
    SUM(total_amount) as revenue,
    COUNT(DISTINCT user_id) as unique_customers
FROM orders
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour;
```

## Product Analytics

### Product Combinations (Frequently Bought Together)
```sql
SELECT 
    oi1.product_id as product_1,
    oi2.product_id as product_2,
    COUNT(*) as times_bought_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id
WHERE oi1.product_id < oi2.product_id
GROUP BY oi1.product_id, oi2.product_id
ORDER BY times_bought_together DESC
LIMIT 10;
```

### Average Product Price
```sql
SELECT 
    product_id,
    COUNT(*) as times_ordered,
    AVG(cost / quantity) as avg_unit_price,
    MIN(cost / quantity) as min_unit_price,
    MAX(cost / quantity) as max_unit_price
FROM order_items
WHERE quantity > 0
GROUP BY product_id
ORDER BY times_ordered DESC;
```

### Products Never Ordered
```sql
-- This requires a products table, which we don't have
-- But you can check which product IDs are missing from order_items
SELECT DISTINCT product_id 
FROM order_items 
ORDER BY product_id;
```

## Performance Queries

### Database Size
```sql
SELECT 
    pg_size_pretty(pg_database_size('orders')) as database_size;
```

### Table Sizes
```sql
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Index Usage
```sql
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### Slow Queries (if pg_stat_statements is enabled)
```sql
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    max_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

## Data Quality Checks

### Check for Null Values
```sql
SELECT 
    COUNT(*) as total_orders,
    COUNT(order_id) as non_null_order_id,
    COUNT(user_id) as non_null_user_id,
    COUNT(total_amount) as non_null_amount
FROM orders;
```

### Check for Orphaned Order Items
```sql
SELECT COUNT(*) as orphaned_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
```

### Check for Invalid Amounts
```sql
SELECT COUNT(*) as invalid_orders
FROM orders
WHERE total_amount <= 0;
```

### Check for Future Dates
```sql
SELECT COUNT(*) as future_orders
FROM orders
WHERE created_at > NOW();
```

## Maintenance Queries

### Vacuum and Analyze
```sql
VACUUM ANALYZE orders;
VACUUM ANALYZE order_items;
```

### Reindex
```sql
REINDEX TABLE orders;
REINDEX TABLE order_items;
```

### Update Statistics
```sql
ANALYZE orders;
ANALYZE order_items;
```

## Export Queries

### Export to CSV (from psql)
```sql
\copy (SELECT * FROM orders ORDER BY created_at DESC) TO '/tmp/orders.csv' CSV HEADER;
\copy (SELECT * FROM order_items) TO '/tmp/order_items.csv' CSV HEADER;
```

### Export Summary Report
```sql
\copy (
    SELECT 
        DATE(created_at) as date,
        COUNT(*) as orders,
        SUM(total_amount) as revenue,
        AVG(total_amount) as avg_order,
        COUNT(DISTINCT user_id) as unique_customers
    FROM orders
    GROUP BY date
    ORDER BY date DESC
) TO '/tmp/daily_summary.csv' CSV HEADER;
```

## Advanced Analytics

### Customer Lifetime Value
```sql
SELECT 
    user_id,
    COUNT(*) as total_orders,
    SUM(total_amount) as lifetime_value,
    AVG(total_amount) as avg_order_value,
    MIN(created_at) as first_order,
    MAX(created_at) as last_order,
    MAX(created_at) - MIN(created_at) as customer_lifetime
FROM orders
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY lifetime_value DESC
LIMIT 20;
```

### Cohort Analysis (by First Order Date)
```sql
WITH first_orders AS (
    SELECT 
        user_id,
        DATE_TRUNC('day', MIN(created_at)) as cohort_date
    FROM orders
    GROUP BY user_id
)
SELECT 
    fo.cohort_date,
    COUNT(DISTINCT fo.user_id) as cohort_size,
    COUNT(DISTINCT CASE WHEN o.created_at > fo.cohort_date + INTERVAL '1 day' THEN o.user_id END) as retained_day_1,
    COUNT(DISTINCT CASE WHEN o.created_at > fo.cohort_date + INTERVAL '7 days' THEN o.user_id END) as retained_day_7
FROM first_orders fo
LEFT JOIN orders o ON fo.user_id = o.user_id
GROUP BY fo.cohort_date
ORDER BY fo.cohort_date DESC;
```

### Revenue Growth Rate
```sql
WITH daily_revenue AS (
    SELECT 
        DATE(created_at) as date,
        SUM(total_amount) as revenue
    FROM orders
    GROUP BY date
)
SELECT 
    date,
    revenue,
    LAG(revenue) OVER (ORDER BY date) as prev_day_revenue,
    revenue - LAG(revenue) OVER (ORDER BY date) as revenue_change,
    ROUND(
        ((revenue - LAG(revenue) OVER (ORDER BY date)) / 
        NULLIF(LAG(revenue) OVER (ORDER BY date), 0) * 100)::numeric, 
        2
    ) as growth_rate_percent
FROM daily_revenue
ORDER BY date DESC
LIMIT 30;
```

### Product Affinity Matrix
```sql
SELECT 
    oi1.product_id as product_a,
    oi2.product_id as product_b,
    COUNT(*) as co_occurrence,
    ROUND(
        COUNT(*)::numeric / 
        (SELECT COUNT(DISTINCT order_id) FROM order_items WHERE product_id = oi1.product_id) * 100,
        2
    ) as affinity_percent
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id
WHERE oi1.product_id != oi2.product_id
GROUP BY oi1.product_id, oi2.product_id
HAVING COUNT(*) > 1
ORDER BY co_occurrence DESC
LIMIT 20;
```

## Grafana Integration

These queries can be used in Grafana with the PostgreSQL data source:

### Time Series Query (for graphs)
```sql
SELECT 
    created_at as time,
    COUNT(*) as orders
FROM orders
WHERE $__timeFilter(created_at)
GROUP BY time
ORDER BY time;
```

### Stat Query (for single value panels)
```sql
SELECT COUNT(*) FROM orders;
```

### Table Query (for table panels)
```sql
SELECT 
    order_id,
    user_id,
    total_amount,
    user_currency,
    created_at
FROM orders
ORDER BY created_at DESC
LIMIT 100;
```

## Useful psql Commands

```sql
-- List all tables
\dt

-- Describe table structure
\d orders
\d order_items

-- List indexes
\di

-- Show table sizes
\dt+

-- Execute SQL file
\i /path/to/file.sql

-- Toggle expanded display
\x

-- Set output format
\pset format wrapped

-- Timing
\timing on

-- Quit
\q
```

## Sample Data Insertion (for Testing)

```sql
-- Insert sample order
INSERT INTO orders (order_id, user_id, user_currency, total_amount, created_at)
VALUES ('test-order-001', 'user-123', 'USD', 99.99, NOW());

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, quantity, cost)
VALUES 
    ('test-order-001', 'OLJCESPC7Z', 1, 49.99),
    ('test-order-001', '66VCHSJNUP', 2, 50.00);
```

## Cleanup Queries

### Delete Old Orders (older than 30 days)
```sql
DELETE FROM order_items 
WHERE order_id IN (
    SELECT order_id FROM orders 
    WHERE created_at < NOW() - INTERVAL '30 days'
);

DELETE FROM orders 
WHERE created_at < NOW() - INTERVAL '30 days';
```

### Truncate All Data
```sql
TRUNCATE TABLE order_items CASCADE;
TRUNCATE TABLE orders CASCADE;
```

## Backup and Restore

### Backup
```bash
kubectl exec -n microservices-demo deployment/postgres -- \
  pg_dump -U orderuser orders > orders_backup_$(date +%Y%m%d).sql
```

### Restore
```bash
kubectl exec -i -n microservices-demo deployment/postgres -- \
  psql -U orderuser orders < orders_backup_20241114.sql
```

### Backup Specific Tables
```bash
kubectl exec -n microservices-demo deployment/postgres -- \
  pg_dump -U orderuser -t orders -t order_items orders > tables_backup.sql
```
