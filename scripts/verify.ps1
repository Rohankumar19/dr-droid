# PowerShell Verification Script for Windows
$ErrorActionPreference = "Continue"

Write-Host "=== Microservices Demo Verification ===" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# Test 1: Check namespaces
Write-Host "1. Checking namespaces..." -ForegroundColor Yellow
try {
    kubectl get namespace microservices-demo 2>&1 | Out-Null
    kubectl get namespace monitoring 2>&1 | Out-Null
    Write-Host "   ✓ Namespaces exist" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Namespaces missing" -ForegroundColor Red
    $allPassed = $false
}

# Test 2: Check microservices pods
Write-Host "2. Checking microservices pods..." -ForegroundColor Yellow
$pods = kubectl get pods -n microservices-demo --no-headers 2>&1
$notRunning = ($pods | Select-String -Pattern "Running|Completed" -NotMatch).Count
if ($notRunning -eq 0) {
    Write-Host "   ✓ All microservices pods running" -ForegroundColor Green
} else {
    Write-Host "   ✗ $notRunning pods not running" -ForegroundColor Red
    kubectl get pods -n microservices-demo | Select-String -Pattern "Running|Completed" -NotMatch
    $allPassed = $false
}

# Test 3: Check monitoring pods
Write-Host "3. Checking monitoring pods..." -ForegroundColor Yellow
$pods = kubectl get pods -n monitoring --no-headers 2>&1
$notRunning = ($pods | Select-String -Pattern "Running|Completed" -NotMatch).Count
if ($notRunning -eq 0) {
    Write-Host "   ✓ All monitoring pods running" -ForegroundColor Green
} else {
    Write-Host "   ✗ $notRunning pods not running" -ForegroundColor Red
    kubectl get pods -n monitoring | Select-String -Pattern "Running|Completed" -NotMatch
    $allPassed = $false
}

# Test 4: Check PostgreSQL
Write-Host "4. Checking PostgreSQL..." -ForegroundColor Yellow
try {
    $result = kubectl exec -n microservices-demo deployment/postgres -- psql -U orderuser -d orders -c "SELECT 1" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ PostgreSQL accessible" -ForegroundColor Green
    } else {
        Write-Host "   ✗ PostgreSQL not accessible" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "   ✗ PostgreSQL not accessible" -ForegroundColor Red
    $allPassed = $false
}

# Test 5: Check Grafana service
Write-Host "5. Checking Grafana service..." -ForegroundColor Yellow
try {
    kubectl get svc prometheus-grafana -n monitoring 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Grafana service exists" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Grafana service missing" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "   ✗ Grafana service missing" -ForegroundColor Red
    $allPassed = $false
}

# Test 6: Check frontend service
Write-Host "6. Checking frontend service..." -ForegroundColor Yellow
try {
    kubectl get svc frontend -n microservices-demo 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Frontend service exists" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Frontend service missing" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "   ✗ Frontend service missing" -ForegroundColor Red
    $allPassed = $false
}

# Test 7: Check CronJob
Write-Host "7. Checking traffic generator..." -ForegroundColor Yellow
try {
    kubectl get cronjob k6-load-test -n microservices-demo 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Traffic generator configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ Traffic generator not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠ Traffic generator not found" -ForegroundColor Yellow
}

# Test 8: Check database tables
Write-Host "8. Checking database schema..." -ForegroundColor Yellow
try {
    $tables = kubectl exec -n microservices-demo deployment/postgres -- psql -U orderuser -d orders -c "\dt" 2>&1
    $tableCount = ($tables | Select-String -Pattern "orders|order_items").Count
    if ($tableCount -ge 2) {
        Write-Host "   ✓ Database tables exist" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Database tables missing" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "   ✗ Database tables missing" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
Write-Host ""

if ($allPassed) {
    Write-Host "✓ All checks passed!" -ForegroundColor Green
} else {
    Write-Host "✗ Some checks failed. Review the output above." -ForegroundColor Red
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Access Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
Write-Host "2. Access Application: kubectl port-forward -n microservices-demo svc/frontend 8080:80"
Write-Host "3. Check database: kubectl exec -it -n microservices-demo deployment/postgres -- psql -U orderuser -d orders"
Write-Host ""
