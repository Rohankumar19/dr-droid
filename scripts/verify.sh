#!/bin/bash

# Verification Script for Microservices Demo
set +e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Microservices Demo Verification ===${NC}"
echo ""

ALL_PASSED=true

# Test 1: Check namespaces
echo -e "${YELLOW}1. Checking namespaces...${NC}"
if kubectl get namespace microservices-demo &> /dev/null && kubectl get namespace monitoring &> /dev/null; then
    echo -e "   ${GREEN}✓ Namespaces exist${NC}"
else
    echo -e "   ${RED}✗ Namespaces missing${NC}"
    ALL_PASSED=false
fi

# Test 2: Check pods in microservices-demo
echo -e "${YELLOW}2. Checking microservices pods...${NC}"
NOT_RUNNING=$(kubectl get pods -n microservices-demo --no-headers 2>/dev/null | grep -v "Running\|Completed" | wc -l)
if [ "$NOT_RUNNING" -eq 0 ]; then
    TOTAL=$(kubectl get pods -n microservices-demo --no-headers 2>/dev/null | wc -l)
    echo -e "   ${GREEN}✓ All $TOTAL microservices pods running${NC}"
else
    echo -e "   ${RED}✗ $NOT_RUNNING pods not running${NC}"
    kubectl get pods -n microservices-demo | grep -v "Running\|Completed" | grep -v "NAME"
    ALL_PASSED=false
fi

# Test 3: Check pods in monitoring
echo -e "${YELLOW}3. Checking monitoring pods...${NC}"
NOT_RUNNING=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | grep -v "Running\|Completed" | wc -l)
if [ "$NOT_RUNNING" -eq 0 ]; then
    TOTAL=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | wc -l)
    echo -e "   ${GREEN}✓ All $TOTAL monitoring pods running${NC}"
else
    echo -e "   ${RED}✗ $NOT_RUNNING pods not running${NC}"
    kubectl get pods -n monitoring | grep -v "Running\|Completed" | grep -v "NAME"
    ALL_PASSED=false
fi

# Test 4: Check PostgreSQL
echo -e "${YELLOW}4. Checking PostgreSQL...${NC}"
if kubectl exec -n microservices-demo deployment/postgres -- psql -U orderuser -d orders -c "SELECT 1" &> /dev/null; then
    echo -e "   ${GREEN}✓ PostgreSQL accessible${NC}"
else
    echo -e "   ${RED}✗ PostgreSQL not accessible${NC}"
    ALL_PASSED=false
fi

# Test 5: Check Grafana service
echo -e "${YELLOW}5. Checking Grafana service...${NC}"
if kubectl get svc prometheus-grafana -n monitoring &> /dev/null; then
    echo -e "   ${GREEN}✓ Grafana service exists${NC}"
else
    echo -e "   ${RED}✗ Grafana service missing${NC}"
    ALL_PASSED=false
fi

# Test 6: Check frontend service
echo -e "${YELLOW}6. Checking frontend service...${NC}"
if kubectl get svc frontend -n microservices-demo &> /dev/null; then
    echo -e "   ${GREEN}✓ Frontend service exists${NC}"
else
    echo -e "   ${RED}✗ Frontend service missing${NC}"
    ALL_PASSED=false
fi

# Test 7: Check CronJob
echo -e "${YELLOW}7. Checking traffic generator...${NC}"
if kubectl get cronjob k6-load-test -n microservices-demo &> /dev/null; then
    echo -e "   ${GREEN}✓ Traffic generator configured${NC}"
else
    echo -e "   ${YELLOW}⚠ Traffic generator not found${NC}"
fi

# Test 8: Check database tables
echo -e "${YELLOW}8. Checking database schema...${NC}"
TABLES=$(kubectl exec -n microservices-demo deployment/postgres -- psql -U orderuser -d orders -c "\dt" 2>/dev/null | grep -c "orders\|order_items")
if [ "$TABLES" -ge 2 ]; then
    echo -e "   ${GREEN}✓ Database tables exist${NC}"
else
    echo -e "   ${RED}✗ Database tables missing${NC}"
    ALL_PASSED=false
fi

# Test 9: Check resource usage
echo -e "${YELLOW}9. Checking resource usage...${NC}"
if command -v kubectl &> /dev/null && kubectl top nodes &> /dev/null; then
    echo -e "   ${GREEN}✓ Metrics server available${NC}"
else
    echo -e "   ${YELLOW}⚠ Metrics server not available (optional)${NC}"
fi

echo ""
echo -e "${CYAN}=== Verification Complete ===${NC}"
echo ""

if [ "$ALL_PASSED" = true ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
else
    echo -e "${RED}✗ Some checks failed. Review the output above.${NC}"
fi

echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "1. Access Grafana:"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "   Then visit: http://localhost:3000 (admin / prom-operator)"
echo ""
echo "2. Access Application:"
echo "   kubectl port-forward -n microservices-demo svc/frontend 8080:80"
echo "   Then visit: http://localhost:8080"
echo ""
echo "3. Check database:"
echo "   kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders"
echo ""
echo "4. View detailed testing guide:"
echo "   cat TESTING_GUIDE.md"
echo ""
