<#
.SYNOPSIS
    Load Generator Script to Demonstrate Kubernetes Horizontal Pod Autoscaler (HPA)
.DESCRIPTION
    Simulates concurrent client requests against the CloudMart Frontend and Order APIs
    to drive CPU utilization and trigger automatic pod scale-out.
#>

param(
    [string]$TargetUrl = "http://localhost:30080",
    [int]$RequestsCount = 200,
    [int]$Concurrency = 5
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " CloudMart: HPA Load Generator & Stress Testing Tool" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Target URL: $TargetUrl" -ForegroundColor Yellow
Write-Host "Total Requests: $RequestsCount" -ForegroundColor Yellow
Write-Host "`nStarting high-throughput request generation..." -ForegroundColor Cyan

$successCount = 0
$failCount = 0

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 1; $i -le $RequestsCount; $i++) {
    try {
        $resp = Invoke-RestMethod -Uri "$TargetUrl/api/proxy/products" -Method Get -TimeoutSec 2
        $successCount++
        if ($i % 25 -eq 0) {
            Write-Host "Sent $i / $RequestsCount requests... (Latest Pod: $($resp.hostname))" -ForegroundColor DarkCyan
        }
    } catch {
        $failCount++
    }
}

$stopwatch.Stop()

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " Load Test Complete in $($stopwatch.Elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Green
Write-Host " Successful Requests: $successCount" -ForegroundColor Cyan
Write-Host " Failed Requests: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "DarkGray" })
Write-Host "`nTo observe pod auto-scaling in action, run:" -ForegroundColor Yellow
Write-Host "  kubectl get hpa -n microservices-lab -w" -ForegroundColor Magenta
Write-Host "  kubectl get pods -n microservices-lab -w" -ForegroundColor Magenta
